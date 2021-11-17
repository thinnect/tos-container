#ifndef TOS_CONTAINER_H_
#define TOS_CONTAINER_H_

/**
 * Initialize the container radio layer. Do this first.
 *
 * @param A functional mist-comm layer.
 * @return 0 for success.
 */
int container_am_radio_init(comms_layer_t* cl);

/**
 * Connect container radio to real radio, done automatically if radio
 * started by container application.
 */
void container_am_radio_connect(void);

/**
 * Disconnect container radio from real radio, not done automatically.
 */
void container_am_radio_disconnect(void);

/**
 * Initialize and boot the container.
 * @param tos_node_id The TinyOS node ID - TOS_NODE_ID.
 */
void container_boot(uint16_t tos_node_id);

/**
 * Poll the container.
 * @return True, if more tasks in queue.
 */
bool container_run(void);

#endif//TOS_CONTAINER_H_
