configuration ActiveMessageC {
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

	#ifdef ACTIVEMESSAGE_DUMMY
		components ActiveMessageDummyP as ActiveMessageP;
	#else
		components ActiveMessageP;
	#endif//ACTIVEMESSAGE_DUMMY
	SplitControl = ActiveMessageP.SplitControl;

	AMSend = ActiveMessageP.AMSend;
	Receive = ActiveMessageP.Receive;
	Snoop = ActiveMessageP.Snoop;
	SendNotifier = ActiveMessageP.SendNotifier;

	Packet = ActiveMessageP.Packet;
	AMPacket = ActiveMessageP.AMPacket;

	PacketAcknowledgements = ActiveMessageP.PacketAcknowledgements;
	LowPowerListening = ActiveMessageP.LowPowerListening;
	PacketLink = ActiveMessageP.PacketLink;
	RadioChannel = ActiveMessageP.RadioChannel;

	//PacketLQI = ActiveMessageP.PacketLQI;
	//PacketRSSI = ActiveMessageP.PacketRSSI;

	PacketLinkQuality = ActiveMessageP.PacketLinkQuality;
	//PacketTransmitPower = ActiveMessageP.PacketTransmitPower;
	PacketRSSI = ActiveMessageP.PacketRSSI;
	//LinkPacketMetadata = ActiveMessageP.LinkPacketMetadata;

	LocalTimeRadio = ActiveMessageP.LocalTimeRadio;
	PacketTimeStampRadio = ActiveMessageP.PacketTimeStampRadio;
	PacketTimeStampMilli = ActiveMessageP.PacketTimeStampMilli;

	TimeSyncAMSendRadio = ActiveMessageP.TimeSyncAMSendRadio;
	TimeSyncPacketRadio = ActiveMessageP.TimeSyncPacketRadio;
	TimeSyncAMSendMilli = ActiveMessageP.TimeSyncAMSendMilli;
	TimeSyncPacketMilli = ActiveMessageP.TimeSyncPacketMilli;

	components LocalTimeMilliC;
	ActiveMessageP.LocalTimeMilli -> LocalTimeMilliC;

}
