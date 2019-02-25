module ActiveMessageC {
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
}
implementation {

	#define __MODUUL__ "am"
	#define __LOG_LEVEL__ (LOG_LEVEL_ActiveMessageC & BASE_LOG_LEVEL)
	#include "log.h"

	task void startDone() {
		signal SplitControl.startDone(SUCCESS);
	}

	task void stopDone() {
		signal SplitControl.stopDone(SUCCESS);
	}

	// SplitControl interface
	command error_t SplitControl.start() {
		return post startDone();
	}

	command error_t SplitControl.stop() {
		return post stopDone();
	}
	// -------------------------------------------------------------------------

	message_t* smsg = NULL;

	task void sendDone() {
		if(smsg != NULL) {
			message_t* m = smsg;
			smsg = NULL;
			debug1("asnt");
			signal AMSend.sendDone[call AMPacket.type(m)](m, SUCCESS);
		}
	}

	// AMSend interface
	command error_t AMSend.send[uint8_t id](am_addr_t addr, message_t* msg, uint8_t len) {
		debug1("asnd[%02X] ->%04X, %d %p", id, addr, len, msg);
		if(smsg == NULL) {
			call AMPacket.setType(msg, id);
			smsg = msg;
			post sendDone();
			return SUCCESS;
		}
		return EBUSY;
	}

	command error_t AMSend.cancel[uint8_t id](message_t* msg) {
		return FAIL;
	}

	command uint8_t AMSend.maxPayloadLength[uint8_t id]() {
		return TOSH_DATA_LENGTH;
	}

	command void* AMSend.getPayload[uint8_t id](message_t* msg, uint8_t len) {
		return msg->data;
	}
	// -------------------------------------------------------------------------

	// Packet interface
	command void Packet.clear(message_t* msg) {
	}

	command uint8_t Packet.payloadLength(message_t* msg) {
		return ((serial_header_t*)(&msg->header))->length;
	}

	command uint8_t Packet.maxPayloadLength() {
		return TOSH_DATA_LENGTH;
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
		return TOS_NODE_ID;
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
		return SUCCESS;
	}

	async command error_t PacketAcknowledgements.noAck(message_t* msg) {
		return SUCCESS;
	}

	async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
		return FALSE;
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
	command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) { }

	command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) { }

  	command uint16_t PacketLink.getRetries(message_t *msg) { return 0; }

	command uint16_t PacketLink.getRetryDelay(message_t *msg) { return 0; }

  	command bool PacketLink.wasDelivered(message_t *msg) { return TRUE; }
  	// -------------------------------------------------------------------------


  	// PacketRSSI interface
	async command bool PacketRSSI.isSet(message_t* msg) {
		return TRUE;
	}
	async command uint8_t PacketRSSI.get(message_t* msg) {
		return 0;
	}
	async command void PacketRSSI.clear(message_t* msg) {
		// TODO
	}
	async command void PacketRSSI.set(message_t* msg, uint8_t value) {
		// TODO
	}
	// -------------------------------------------------------------------------

	// PacketLinkQuality interface
	async command bool PacketLinkQuality.isSet(message_t* msg) {
		return TRUE;
	}
	async command uint8_t PacketLinkQuality.get(message_t* msg) {
		return 0xFF;
	}
	async command void PacketLinkQuality.clear(message_t* msg) {
		// TODO
	}
	async command void PacketLinkQuality.set(message_t* msg, uint8_t value) {
		// TODO
	}
	// -------------------------------------------------------------------------

	// LocalTimeRadio interface
	async command uint32_t LocalTimeRadio.get() {
		return 0;
	}
	// -------------------------------------------------------------------------


	// PacketTimeStampRadio interface
	async command bool PacketTimeStampRadio.isValid(message_t* msg) {
		return FALSE;
	}
	async command uint32_t PacketTimeStampRadio.timestamp(message_t* msg) {
		return 0;
	}
	async command void PacketTimeStampRadio.clear(message_t* msg) {
		// TODO
	}
	async command void PacketTimeStampRadio.set(message_t* msg, uint32_t value) {
		// TODO
		debug1("PTSR.set %p %"PRIu32, msg, value);
	}
	// -------------------------------------------------------------------------

	// PacketTimeStampMilli interface
	async command bool PacketTimeStampMilli.isValid(message_t* msg) {
		return FALSE;
	}
	async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg) {
		return 0;
	}
	async command void PacketTimeStampMilli.clear(message_t* msg) {
		// TODO
	}
	async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value) {
		// TODO
		debug1("PTSM.set %p %"PRIu32, msg, value);
	}
	// -------------------------------------------------------------------------

	message_t* trmsg;

	task void timeSyncRadioSendDone() {
		if(trmsg != NULL) {
			message_t* m = trmsg;
			trmsg = NULL;
			debug1("trsnt");
			signal TimeSyncAMSendRadio.sendDone[call AMPacket.type(m)](m, SUCCESS);
		}
	}

	// TimeSyncAMSendRadio interface
	command error_t TimeSyncAMSendRadio.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time) {
		debug1("trsnd[%02X] ->%04X, %d @%"PRIu32" %p", id, addr, len, event_time, msg);
		if(trmsg == NULL) {
			call AMPacket.setType(msg, id);
			trmsg = msg;
			post timeSyncRadioSendDone();
			return SUCCESS;
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

	message_t* tmmsg;

	task void timeSyncMilliSendDone() {
		if(tmmsg != NULL) {
			message_t* m = tmmsg;
			tmmsg = NULL;
			debug1("tmsnt");
			signal TimeSyncAMSendMilli.sendDone[call AMPacket.type(m)](m, SUCCESS);
		}
	}

	// TimeSyncAMSendMilli interface
	command error_t TimeSyncAMSendMilli.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time) {
		debug1("tmsnd[%02X] ->%04X, %d @%"PRIu32" %p", id, addr, len, event_time, msg);
		if(tmmsg == NULL) {
			call AMPacket.setType(msg, id);
			tmmsg = msg;
			post timeSyncMilliSendDone();
			return SUCCESS;
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
		return FALSE;
	}

	command uint32_t TimeSyncPacketRadio.eventTime(message_t* msg) {
		return 0;
	}
	// -------------------------------------------------------------------------

	// TimeSyncPacketMilli interface
	command bool TimeSyncPacketMilli.isValid(message_t* msg) {
		return FALSE;
	}

	command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg) {
		return 0;
	}
	// -------------------------------------------------------------------------

}
