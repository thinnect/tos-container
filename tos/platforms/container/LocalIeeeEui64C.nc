#include "IeeeEui64.h"
module LocalIeeeEui64C {
	provides interface LocalIeeeEui64;
}
implementation {

	command ieee_eui64_t LocalIeeeEui64.getId () {
		// TODO return value from external API
		ieee_eui64_t eui = {{0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07}};
		return eui;
	}

}
