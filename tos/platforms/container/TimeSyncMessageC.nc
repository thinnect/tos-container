// Just wire against the containers ActiveMessageC
configuration TimeSyncMessageC {
	provides {
		interface SplitControl;

		interface Receive[uint8_t id];
		interface Receive as Snoop[am_id_t id];
		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;
		interface LowPowerListening;

		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacketRadio;

		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
	}
}
implementation {

	components ActiveMessageC as MessageC;

	SplitControl           = MessageC;
	Receive                = MessageC.Receive;
	Snoop                  = MessageC.Snoop;
	Packet                 = MessageC;
	AMPacket               = MessageC;
	PacketAcknowledgements = MessageC;
	LowPowerListening      = MessageC;

	PacketTimeStampRadio = MessageC.PacketTimeStampRadio;
	TimeSyncAMSendRadio  = MessageC.TimeSyncAMSendRadio;
	TimeSyncPacketRadio  = MessageC.TimeSyncPacketRadio;

	PacketTimeStampMilli = MessageC.PacketTimeStampMilli;
	TimeSyncAMSendMilli  = MessageC.TimeSyncAMSendMilli;
	TimeSyncPacketMilli  = MessageC.TimeSyncPacketMilli;

}
