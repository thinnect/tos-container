#include "mist_comm.h"
#include "mist_comm_am.h"
module ActiveMessageP {
	provides {
		interface SplitControl;

		interface AMSend[uint8_t id];
		interface Receive[uint8_t id];
		interface Receive as Snoop[uint8_t id];
		interface SendNotifier[am_id_t id];

		interface Packet;
		interface AMPacket;

		interface PacketAcknowledgements;
		interface LowPowerListening;
		interface PacketLink;
		interface RadioChannel;

		//interface PacketField<uint8_t> as PacketLQI;
		//interface PacketField<uint8_t> as PacketRSSI;

		interface PacketField<uint8_t> as PacketLinkQuality;
		//interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		//interface LinkPacketMetadata;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

		interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacketRadio;
		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
	}
	uses {
		interface LocalTime<TMilli> as LocalTimeMilli;

		interface Queue<message_t*> as RxQueue;
		interface Pool<message_t> as RxPool;
	}
}
implementation {

	#define __MODUUL__ "am"
	#define __LOG_LEVEL__ (LOG_LEVEL_ActiveMessageP & BASE_LOG_LEVEL)
	#include "log.h"

	enum ActiveMessageStates {
		ST_OFF,
		ST_STARTING,
		ST_RUNNING,
		ST_STOPPING
	};

	uint8_t m_state = ST_OFF;

	const uint8_t rcvids[] = {0x3D, 0xB0, 0xB1, 0xB2, 0xB7}; // TODO the list should come from build process
	comms_receiver_t m_receivers[sizeof(rcvids)];

	comms_layer_t* m_radio = NULL;

	bool m_radio_set_up = FALSE;

	int container_am_radio_init(comms_layer_t* cl) @C() @spontaneous() {
		m_radio = cl;
		return 0;
	}

	error_t tosToComms(comms_msg_t* cmsg, message_t* msg) {
		uint8_t len = call Packet.payloadLength(msg);
		void* payload;

		comms_init_message(m_radio, cmsg);

		comms_set_packet_type(m_radio, cmsg, call AMPacket.type(msg));
		comms_am_set_destination(m_radio, cmsg, call AMPacket.destination(msg));
		comms_am_set_source(m_radio, cmsg, call AMPacket.address());

		if(((radio_metadata_t*)(msg->metadata))->timestamp_valid) {
			comms_set_timestamp(m_radio, cmsg, ((radio_metadata_t*)(msg->metadata))->timestamp);
		}

		if(((radio_metadata_t*)(msg->metadata))->event_time_valid) {
			comms_set_event_time(m_radio, cmsg, ((radio_metadata_t*)(msg->metadata))->event_time);
		}

		comms_set_ack_required(m_radio, cmsg, ((radio_metadata_t*)(msg->metadata))->ack_requested);

		payload = comms_get_payload(m_radio, cmsg, len);
		if(payload == NULL) {
			return ESIZE;
		}
		memcpy(payload, call Packet.getPayload(msg, len), len);
		comms_set_payload_length(m_radio, cmsg, len);

		return SUCCESS;
	}

	error_t commsToTos(message_t* msg, const comms_msg_t* cmsg) {
		uint8_t len = comms_get_payload_length(m_radio, cmsg);
		void* payload;

		call Packet.clear(msg);

		call AMPacket.setType(msg, comms_get_packet_type(m_radio, cmsg));
		call AMPacket.setDestination(msg, comms_am_get_destination(m_radio, cmsg));
		call AMPacket.setSource(msg, comms_am_get_source(m_radio, cmsg));

		((radio_metadata_t*)(msg->metadata))->timestamp = comms_get_timestamp(m_radio, cmsg);
		((radio_metadata_t*)(msg->metadata))->timestamp_valid = comms_timestamp_valid(m_radio, cmsg);

		((radio_metadata_t*)(msg->metadata))->event_time = comms_get_event_time(m_radio, cmsg);
		((radio_metadata_t*)(msg->metadata))->event_time_valid = comms_event_time_valid(m_radio, cmsg);

		((radio_metadata_t*)(msg->metadata))->ack_received = comms_ack_received(m_radio, cmsg);

		call PacketLinkQuality.set(msg, comms_get_lqi(m_radio, cmsg));
		call PacketRSSI.set(msg, (90+comms_get_rssi(m_radio, cmsg))/3 + 1); // RFR2 RSSI 0-28 units

		payload = call Packet.getPayload(msg, len);
		if(payload == NULL) {
			return ESIZE;
		}
		memcpy(payload, comms_get_payload(m_radio, cmsg, len), len);
		call Packet.setPayloadLength(msg, len);

		return SUCCESS;
	}

	default event message_t* Receive.receive[uint8_t id](message_t* msg, void* payload, uint8_t length) { return msg; }

	task void receivedMessage() {
		message_t* msg = NULL;
		atomic {
			while(!call RxQueue.empty()) {
				msg = call RxQueue.dequeue();
				if(m_state != ST_RUNNING) {
					debug1("rcv off q:%d", call RxQueue.size());
					call RxPool.put(msg);
					msg = NULL;
				}
				else {
					break; // process the message
				}
			}
		}
		if(msg != NULL) {
			uint8_t length = call Packet.payloadLength(msg);

			if(call TimeSyncPacketMilli.isValid(msg)) {
				debug1("rcv %02"PRIX8" %04"PRIX16" r:%"PRIu8" age=%"PRIi32,
					   call AMPacket.type(msg), call AMPacket.source(msg),
                       call PacketRSSI.get(msg),
				       call LocalTimeMilli.get() - call TimeSyncPacketMilli.eventTime(msg));
			}
			else {
				debug1("rcv %02"PRIX8" %04"PRIX16" r:%"PRIu8,
					   call AMPacket.type(msg), call AMPacket.source(msg),
					   call PacketRSSI.get(msg));
			}

			msg = signal Receive.receive[call AMPacket.type(msg)](msg, call Packet.getPayload(msg, length), length);

			atomic {
				call RxPool.put(msg);
				if(!call RxQueue.empty()) {
					post receivedMessage();
				}
			}
		}
	}

	void commsReceive(comms_layer_t* comms, const comms_msg_t* msg, void* user) {
		atomic {
			if(m_state == ST_RUNNING) {
				message_t* pm = call RxPool.get();
				if(pm != NULL) {
					if(commsToTos(pm, msg) == SUCCESS) {
						error_t r = call RxQueue.enqueue(pm);
						if(r == SUCCESS) {
							post receivedMessage();
							return;
						}
						else warn1("rcv e:%d q:%d", r, call RxQueue.size());
					}
					else err1("rcv cpy");
					call RxPool.put(pm);
				}
				else warn1("rcv p:%d q:%d", call RxPool.size(), call RxQueue.size());
			}
			else debug1("rcv off");
		}
	}

	task void startDone() {
		if(m_radio_set_up == FALSE) {
			uint8_t i;
			for(i=0;i<sizeof(rcvids);i++) {
				comms_register_recv(m_radio, &m_receivers[i], commsReceive, NULL, rcvids[i]);
			}
			m_radio_set_up = TRUE;
		}
		signal SplitControl.startDone(SUCCESS);
		m_state = ST_RUNNING; // Will not let anything be done from the startDone event
	}

	task void stopDone() {
		//uint8_t i;
		//for(i=0;i<sizeof(rcvids);i++) {
		//	comms_deregister_recv(m_radio, &m_receivers[i]);
		//}
		m_state = ST_OFF;
		signal SplitControl.stopDone(SUCCESS);
	}

	// SplitControl interface
	command error_t SplitControl.start() {
		if(m_radio == NULL) {
			return ENOMEM;
		}
		if(m_state == ST_RUNNING) {
			return EALREADY;
		}
		if(m_state == ST_OFF) {
			m_state = ST_STARTING;
			post startDone();
			return SUCCESS;
		}
		return EBUSY;
	}

	command error_t SplitControl.stop() {
		if(m_state == ST_OFF) {
			return EALREADY;
		}
		if(m_state == ST_RUNNING) {
			m_state = ST_STOPPING;
			post stopDone();
			return SUCCESS;
		}
		return EBUSY;
	}
	// -------------------------------------------------------------------------

	comms_msg_t s_commsmsg;
	message_t* s_tosmsg = NULL;
	error_t s_result;

	task void sendDone() {
		if(s_tosmsg != NULL) {
			message_t* m = s_tosmsg;
			s_tosmsg = NULL;
			commsToTos(m, &s_commsmsg);
			debug1("asnt");
			signal AMSend.sendDone[call AMPacket.type(m)](m, s_result);
		}
	}

	void commsSendDone(comms_layer_t* comms, comms_msg_t* msg, comms_error_t result, void* user) {
		if(result == COMMS_SUCCESS) {
			s_result = SUCCESS;
		}
		else {
			s_result = FAIL; // TODO map failure values
		}
		post sendDone();
	}

	// AMSend interface
	command error_t AMSend.send[uint8_t id](am_addr_t addr, message_t* msg, uint8_t len) {
		debug1("asnd[%02X] ->%04X, %d %p", id, addr, len, msg);
		if(s_tosmsg == NULL) {
			call Packet.setPayloadLength(msg, len);
			call AMPacket.setType(msg, id);
			call AMPacket.setDestination(msg, addr);

			if(tosToComms(&s_commsmsg, msg) == SUCCESS) {
				comms_error_t err = comms_send(m_radio, &s_commsmsg, &commsSendDone, msg);
				debug1("send(%p)=%d", &s_commsmsg, err);
				if(err == COMMS_SUCCESS) {
					s_tosmsg = msg;
					return SUCCESS;
				}
				return FAIL;
			}
			return EINVAL;
		}
		return EBUSY;
	}

	command error_t AMSend.cancel[uint8_t id](message_t* msg) {
		return FAIL;
	}

	command uint8_t AMSend.maxPayloadLength[uint8_t id]() {
		return comms_get_payload_max_length(m_radio);
	}

	command void* AMSend.getPayload[uint8_t id](message_t* msg, uint8_t len) {
		return msg->data;
	}
	// -------------------------------------------------------------------------

	// Packet interface
	command void Packet.clear(message_t* msg) {
		memset(msg, 0, sizeof(message_t));
	}

	command uint8_t Packet.payloadLength(message_t* msg) {
		return ((serial_header_t*)(&msg->header))->length;
	}

	command uint8_t Packet.maxPayloadLength() {
		return comms_get_payload_max_length(m_radio);
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len) {
		return msg->data;
	}

	command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
		((serial_header_t*)(&msg->header))->length = len;
	}
	// -------------------------------------------------------------------------

	//  nx_am_addr_t dest;
	//  nx_am_addr_t src;
	//  nx_uint8_t length;
	//  nx_am_group_t group;
	//  nx_am_id_t type;

	// AMPacket interface
	command am_addr_t AMPacket.address() {
		return comms_am_address(m_radio);
	}

	command am_addr_t AMPacket.destination(message_t* amsg) {
		return ((serial_header_t*)(&amsg->header))->dest;
	}

	command bool AMPacket.isForMe(message_t* amsg) {
		am_addr_t dest = ((serial_header_t*)(&amsg->header))->dest;
		return dest == call AMPacket.address() || dest == AM_BROADCAST_ADDR;
	}

	command am_id_t AMPacket.type(message_t* amsg) {
		return ((serial_header_t*)(&amsg->header))->type;
	}

	command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
		((serial_header_t*)(&amsg->header))->dest = addr;
	}

	command void AMPacket.setType(message_t* amsg, am_id_t t) {
		((serial_header_t*)(&amsg->header))->type = t;
	}

	command am_addr_t AMPacket.source(message_t* amsg) {
		return ((serial_header_t*)(&amsg->header))->src;
	}

	command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
		((serial_header_t*)(&amsg->header))->src = addr;
	}

	command am_group_t AMPacket.group(message_t* amsg) {
		return ((serial_header_t*)(&amsg->header))->group;
	}

	command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
		((serial_header_t*)(&amsg->header))->group = grp;
	}

	command am_group_t AMPacket.localGroup() {
		return TOS_AM_GROUP;
	}
	// -------------------------------------------------------------------------

	// PacketAcknowledgements interface
	async command error_t PacketAcknowledgements.requestAck(message_t* msg) {
		((radio_metadata_t*)(msg->metadata))->ack_requested = TRUE;
		return SUCCESS;
	}

	async command error_t PacketAcknowledgements.noAck(message_t* msg) {
		((radio_metadata_t*)(msg->metadata))->ack_requested = FALSE;
		return SUCCESS;
	}

	async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->ack_received;
	}
	// -------------------------------------------------------------------------

	uint8_t m_channel = 0;

	task void setChannelDone() {
		signal RadioChannel.setChannelDone();
	}

	// RadioChannel interface
	command error_t RadioChannel.setChannel(uint8_t channel) {
		m_channel = channel;
		return post setChannelDone();
	}

	command uint8_t RadioChannel.getChannel() {
		return m_channel;
	}
	// -------------------------------------------------------------------------

	// LowPowerListening interface
	command void LowPowerListening.setLocalWakeupInterval(uint16_t intervalMs) { }

	command uint16_t LowPowerListening.getLocalWakeupInterval() { return 0; }

	command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs) { }

	command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) { return 0; }
	// -------------------------------------------------------------------------

	// PacketLink interface
	command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) {
		((radio_metadata_t*)(msg->metadata))->ack_requested = TRUE;
	}

	command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) { }

  	command uint16_t PacketLink.getRetries(message_t *msg) { return 0; }

	command uint16_t PacketLink.getRetryDelay(message_t *msg) { return 0; }

  	command bool PacketLink.wasDelivered(message_t *msg) {
  		return ((radio_metadata_t*)(msg->metadata))->ack_received;
  	}
  	// -------------------------------------------------------------------------


  	// PacketRSSI interface
	async command bool PacketRSSI.isSet(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->rssi_set;
	}
	async command uint8_t PacketRSSI.get(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->rssi;
	}
	async command void PacketRSSI.clear(message_t* msg) {
		((radio_metadata_t*)(msg->metadata))->rssi_set = FALSE;
	}
	async command void PacketRSSI.set(message_t* msg, uint8_t value) {
		((radio_metadata_t*)(msg->metadata))->rssi_set = TRUE;
		((radio_metadata_t*)(msg->metadata))->rssi = value;
	}
	// -------------------------------------------------------------------------

	// PacketLinkQuality interface
	async command bool PacketLinkQuality.isSet(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->lqi_set;
	}
	async command uint8_t PacketLinkQuality.get(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->lqi;
	}
	async command void PacketLinkQuality.clear(message_t* msg) {
		((radio_metadata_t*)(msg->metadata))->lqi_set = FALSE;
	}
	async command void PacketLinkQuality.set(message_t* msg, uint8_t value) {
		((radio_metadata_t*)(msg->metadata))->lqi_set = TRUE;
		((radio_metadata_t*)(msg->metadata))->lqi = value;
	}
	// -------------------------------------------------------------------------

	// LocalTimeRadio interface
	async command uint32_t LocalTimeRadio.get() {
		return call LocalTimeMilli.get();
	}
	// -------------------------------------------------------------------------


	// PacketTimeStampRadio interface
	async command bool PacketTimeStampRadio.isValid(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->timestamp_valid;
	}
	async command uint32_t PacketTimeStampRadio.timestamp(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->timestamp;
	}
	async command void PacketTimeStampRadio.clear(message_t* msg) {
		((radio_metadata_t*)(msg->metadata))->timestamp_valid = FALSE;
	}
	async command void PacketTimeStampRadio.set(message_t* msg, uint32_t value) {
		debug1("PTSR.set %p %"PRIu32, msg, value);
		((radio_metadata_t*)(msg->metadata))->timestamp_valid = TRUE;
		((radio_metadata_t*)(msg->metadata))->timestamp = value;
	}
	// -------------------------------------------------------------------------

	// PacketTimeStampMilli interface
	async command bool PacketTimeStampMilli.isValid(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->timestamp_valid;
	}
	async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->timestamp;
	}
	async command void PacketTimeStampMilli.clear(message_t* msg) {
		((radio_metadata_t*)(msg->metadata))->timestamp_valid = FALSE;
	}
	async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value) {
		debug1("PTSM.set %p %"PRIu32, msg, value);
		((radio_metadata_t*)(msg->metadata))->timestamp_valid = TRUE;
		((radio_metadata_t*)(msg->metadata))->timestamp = value;
	}
	// -------------------------------------------------------------------------

	message_t* s_tr_tosmsg = NULL;
	comms_msg_t s_tr_commsmsg;
	error_t s_tr_result;

	task void timeSyncRadioSendDone() {
		if(s_tr_tosmsg != NULL) {
			message_t* m = s_tr_tosmsg;
			s_tr_tosmsg = NULL;
			commsToTos(m, &s_tr_commsmsg);
			debug1("trsnt");
			signal TimeSyncAMSendRadio.sendDone[call AMPacket.type(m)](m, s_tr_result);
		}
	}

	void commsTimestampRadioSendDone(comms_layer_t* comms, comms_msg_t* msg, comms_error_t result, void* user) {
		if(result == COMMS_SUCCESS) {
			s_tr_result = SUCCESS;
		}
		else {
			s_tr_result = FAIL; // TODO map failure values
		}
		post timeSyncRadioSendDone();
	}

	// TimeSyncAMSendRadio interface
	command error_t TimeSyncAMSendRadio.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time) {
		debug1("trsnd[%02X] ->%04X, %d @%"PRIu32" %p", id, addr, len, event_time, msg);
		if(s_tr_tosmsg == NULL) {
			call Packet.setPayloadLength(msg, len);
			call AMPacket.setType(msg, id);
			call AMPacket.setDestination(msg, addr);
			((radio_metadata_t*)(msg->metadata))->event_time = event_time;
			((radio_metadata_t*)(msg->metadata))->event_time_valid = TRUE;

			if(tosToComms(&s_tr_commsmsg, msg) == SUCCESS) {
				comms_error_t err = comms_send(m_radio, &s_tr_commsmsg, &commsTimestampRadioSendDone, msg);
				debug1("send(%p)=%d", &s_tr_commsmsg, err);
				if(err == COMMS_SUCCESS) {
					s_tr_tosmsg = msg;
					return SUCCESS;
				}
				return FAIL;
			}
			return EINVAL;
		}
		return EBUSY;
	}
	command error_t TimeSyncAMSendRadio.cancel[am_id_t id](message_t* msg) {
		return FAIL;
	}
	// event void sendDone[am_id_t id](message_t* msg, error_t error);
	command uint8_t TimeSyncAMSendRadio.maxPayloadLength[am_id_t id]() {
		return call AMSend.maxPayloadLength[id]() - 4;
	}
	command void* TimeSyncAMSendRadio.getPayload[am_id_t id](message_t* msg, uint8_t len) {
		return call AMSend.getPayload[id](msg, len - 4);
	}

	default event void TimeSyncAMSendRadio.sendDone[am_id_t id](message_t* msg, error_t error) {
		err1("panic");
	}

	// -------------------------------------------------------------------------

	message_t* s_tm_tosmsg = NULL;
	comms_msg_t s_tm_commsmsg;
	error_t s_tm_result;

	task void timeSyncMilliSendDone() {
		if(s_tm_tosmsg != NULL) {
			message_t* m = s_tm_tosmsg;
			s_tm_tosmsg = NULL;
			commsToTos(m, &s_tm_commsmsg);
			debug1("tmsnt");
			signal TimeSyncAMSendMilli.sendDone[call AMPacket.type(m)](m, s_tm_result);
		}
	}

	void commsTimestampMilliSendDone(comms_layer_t* comms, comms_msg_t* msg, comms_error_t result, void* user) {
		if(result == COMMS_SUCCESS) {
			s_tm_result = SUCCESS;
		}
		else {
			s_tm_result = FAIL; // TODO map failure values
		}
		post timeSyncMilliSendDone();
	}

	// TimeSyncAMSendMilli interface
	command error_t TimeSyncAMSendMilli.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time) {
		debug1("tmsnd[%02X] ->%04X, %d @%"PRIu32" %p", id, addr, len, event_time, msg);
		if(s_tm_tosmsg == NULL) {
			call Packet.setPayloadLength(msg, len);
			call AMPacket.setType(msg, id);
			call AMPacket.setDestination(msg, addr);
			((radio_metadata_t*)(msg->metadata))->event_time = event_time;
			((radio_metadata_t*)(msg->metadata))->event_time_valid = TRUE;

			if(tosToComms(&s_tm_commsmsg, msg) == SUCCESS) {
				comms_error_t err = comms_send(m_radio, &s_tm_commsmsg, &commsTimestampMilliSendDone, msg);
				debug1("send(%p)=%d", &s_tm_commsmsg, err);
				if(err == COMMS_SUCCESS) {
					s_tm_tosmsg = msg;
					return SUCCESS;
				}
				return FAIL;
			}
			return EINVAL;
		}
		return EBUSY;
	}
	command error_t TimeSyncAMSendMilli.cancel[am_id_t id](message_t* msg) {
		return FAIL;
	}
	// event void sendDone[am_id_t id](message_t* msg, error_t error);
	command uint8_t TimeSyncAMSendMilli.maxPayloadLength[am_id_t id]() {
		return call AMSend.maxPayloadLength[id]() - 4;
	}
	command void* TimeSyncAMSendMilli.getPayload[am_id_t id](message_t* msg, uint8_t len) {
		return call AMSend.getPayload[id](msg, len - 4);
	}

	default event void TimeSyncAMSendMilli.sendDone[am_id_t id](message_t* msg, error_t error) {
		err1("panic");
	}

	// -------------------------------------------------------------------------

	// TimeSyncPacketRadio interface
	command bool TimeSyncPacketRadio.isValid(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->event_time_valid;
	}

	command uint32_t TimeSyncPacketRadio.eventTime(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->event_time;
	}
	// -------------------------------------------------------------------------

	// TimeSyncPacketMilli interface
	command bool TimeSyncPacketMilli.isValid(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->event_time_valid;
	}

	command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg) {
		return ((radio_metadata_t*)(msg->metadata))->event_time;
	}
	// -------------------------------------------------------------------------

}
