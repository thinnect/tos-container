#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include <Serial.h>

typedef union message_header {
	// TODO some "radio" header
	serial_header_t serial;
} message_header_t;

typedef union message_footer {
	// TODO some "radio" footer
} message_footer_t;

typedef union message_metadata {
	// TODO some "radio" metadata
} message_metadata_t;

#endif
