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

typedef struct radio_metadata {
	uint32_t timestamp;
	bool timestamp_valid;

	uint32_t event_time;
	bool event_time_valid;

	uint8_t lqi;
	bool lqi_set;

	uint8_t rssi;
	bool rssi_set;

	bool ack_requested;
	bool ack_received;
} radio_metadata_t;

typedef union message_metadata {
	radio_metadata_t radio;
} message_metadata_t;

#endif
