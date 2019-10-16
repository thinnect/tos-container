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
 * Initialize and boot the container.
 * @param tos_node_id The TinyOS node ID - TOS_NODE_ID.
 */
void container_boot(uint16_t tos_node_id);

/**
 * Poll the container.
 * @return True, if more tasks in queue.
 */
bool container_run();

#endif//TOS_CONTAINER_H_
