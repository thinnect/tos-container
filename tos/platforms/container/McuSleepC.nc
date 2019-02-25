module McuSleepC {
	provides {
		interface McuSleep;
		interface McuPowerState;
	}
}
implementation {

	async command void McuSleep.sleep() { }
	async command void McuSleep.irq_preamble() { }
	async command void McuSleep.irq_postamble() { }
	async command void McuPowerState.update() { }

}
