module GpioC
{
    provides
    {
        interface Gpio as Pin1; 
        interface Gpio as Pin2; 
        interface Gpio as Pin3; 
        interface Gpio as Pin4; 
    }
}

implementation
{
    extern void PLATFORM_SetGpioPin (uint8_t pin_nr) @C();
    extern void PLATFORM_ClearGpioPin (uint8_t pin_nr) @C();
    extern void PLATFORM_GetGpioPin (uint8_t pin_nr) @C();
    extern void PLATFORM_ToggleGpioPin (uint8_t pin_nr) @C();

    /**************************************************************************
     *  Set pin 1 in TSB header JP1
     *************************************************************************/
    async command void Pin1.set ()
    {
        PLATFORM_SetGpioPin(1);
    }

    /**************************************************************************
     *  Clear pin 1 in TSB header JP1
     *************************************************************************/
    async command void Pin1.clr ()
    {
        PLATFORM_ClearGpioPin(1);
    }

    /**************************************************************************
     *  Toggle pin 1 in TSB header JP1
     *************************************************************************/
    async command void Pin1.toggle ()
    {
        PLATFORM_ToggleGpioPin(1);
    }

    /**************************************************************************
     *  Get pin 1 value in TSB header JP1
     *************************************************************************/
    async command bool Pin1.get ()
    {
        // TODO Implement get
        return 0;
    }

    /**************************************************************************
     *  Make pin 1 in TSB header JP1 to an input
     *************************************************************************/
    async command void Pin1.makeInput ()
    {
        // TODO
    }
    
    /**************************************************************************
     *  Returns true when pin 1 is input
     *************************************************************************/
    async command bool Pin1.isInput ()
    {
        // TODO
        return FALSE;
    }
    
    /**************************************************************************
     *  Make pin 1 in TSB header JP1 to an output
     *************************************************************************/
    async command void Pin1.makeOutput ()
    {
        // TODO
    }

    /**************************************************************************
     *  Returns true when pin 1 is output
     *************************************************************************/
    async command bool Pin1.isOutput ()
    {
        // TODO
        return TRUE;
    }

    /**************************************************************************
     *  Set pin 2 in TSB header JP1
     *************************************************************************/
    async command void Pin2.set ()
    {
        PLATFORM_SetGpioPin(2);
    }

    /**************************************************************************
     *  Clear pin 2 in TSB header JP1
     *************************************************************************/
    async command void Pin2.clr ()
    {
        PLATFORM_ClearGpioPin(2);
    }

    /**************************************************************************
     *  Toggle pin 2 in TSB header JP1
     *************************************************************************/
    async command void Pin2.toggle ()
    {
        PLATFORM_ToggleGpioPin(2);
    }

    /**************************************************************************
     *  Get pin 2 value in TSB header JP1
     *************************************************************************/
    async command bool Pin2.get ()
    {
        // TODO Implement get
        return 0;
    }

    /**************************************************************************
     *  Make pin 2 in TSB header JP1 to an input
     *************************************************************************/
    async command void Pin2.makeInput ()
    {
        // TODO
    }
    
    /**************************************************************************
     *  Returns true when pin 2 is input
     *************************************************************************/
    async command bool Pin2.isInput ()
    {
        // TODO
        return FALSE;
    }
    
    /**************************************************************************
     *  Make pin 2 in TSB header JP1 to an output
     *************************************************************************/
    async command void Pin2.makeOutput ()
    {
        // TODO
    }

    /**************************************************************************
     *  Returns true when pin 2 is output
     *************************************************************************/
    async command bool Pin2.isOutput ()
    {
        // TODO
        return TRUE;
    }

    /**************************************************************************
     *  Set pin 3 in TSB header JP1
     *************************************************************************/
    async command void Pin3.set ()
    {
        PLATFORM_SetGpioPin(3);
    }

    /**************************************************************************
     *  Clear pin 3 in TSB header JP1
     *************************************************************************/
    async command void Pin3.clr ()
    {
        PLATFORM_ClearGpioPin(3);
    }

    /**************************************************************************
     *  Toggle pin 3 in TSB header JP1
     *************************************************************************/
    async command void Pin3.toggle ()
    {
        PLATFORM_ToggleGpioPin(3);
    }

    /**************************************************************************
     *  Get pin 3 value in TSB header JP1
     *************************************************************************/
    async command bool Pin3.get ()
    {
        // TODO Implement get
        return 0;
    }

    /**************************************************************************
     *  Make pin 3 in TSB header JP1 to an input
     *************************************************************************/
    async command void Pin3.makeInput ()
    {
        // TODO
    }
    
    /**************************************************************************
     *  Returns true when pin 3 is input
     *************************************************************************/
    async command bool Pin3.isInput ()
    {
        // TODO
        return FALSE;
    }
    
    /**************************************************************************
     *  Make pin 3 in TSB header JP1 to an output
     *************************************************************************/
    async command void Pin3.makeOutput ()
    {
        // TODO
    }

    /**************************************************************************
     *  Returns true when pin 3 is output
     *************************************************************************/
    async command bool Pin3.isOutput ()
    {
        // TODO
        return TRUE;
    }

    /**************************************************************************
     *  Set pin 4 in TSB header JP1
     *************************************************************************/
    async command void Pin4.set ()
    {
        PLATFORM_SetGpioPin(4);
    }

    /**************************************************************************
     *  Clear pin 4 in TSB header JP1
     *************************************************************************/
    async command void Pin4.clr ()
    {
        PLATFORM_ClearGpioPin(4);
    }

    /**************************************************************************
     *  Toggle pin 4 in TSB header JP1
     *************************************************************************/
    async command void Pin4.toggle ()
    {
        PLATFORM_ToggleGpioPin(4);
    }

    /**************************************************************************
     *  Get pin 4 value in TSB header JP1
     *************************************************************************/
    async command bool Pin4.get ()
    {
        // TODO Implement get
        return 0;
    }

    /**************************************************************************
     *  Make pin 4 in TSB header JP1 to an input
     *************************************************************************/
    async command void Pin4.makeInput ()
    {
        // TODO
    }
    
    /**************************************************************************
     *  Returns true when pin 4 is input
     *************************************************************************/
    async command bool Pin4.isInput ()
    {
        // TODO
        return FALSE;
    }
    
    /**************************************************************************
     *  Make pin 4 in TSB header JP1 to an output
     *************************************************************************/
    async command void Pin4.makeOutput ()
    {
        // TODO
    }

    /**************************************************************************
     *  Returns true when pin 4 is output
     *************************************************************************/
    async command bool Pin4.isOutput ()
    {
        // TODO
        return TRUE;
    }


}
