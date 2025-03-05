// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * GRUB 2 module to set the QNAP status LED via the IT8528 EC.
 *
 * This module would set the status LED to a green-red alternating
 * pattern.
 *
 * Version history:
 *	v1.0: Initial version.
 */

#include <grub/dl.h>
#include <grub/time.h>
#include <grub/cpu/io.h>

GRUB_MOD_LICENSE ("GPLv3+");

/*
 * qnap8528led_wait_ibf_clear
 * Wait for the EC input buffer to be clear for writing
 */
static grub_err_t qnap8528led_ec_wait_ibf(void) {
    grub_uint16_t retries = 0;
    do {
        if (!(grub_inb(0x6c) & 2))
            return 0;
        grub_millisleep(1);
    } while (retries++ < 1000);
    return grub_error(GRUB_ERR_TIMEOUT, N_("Timeout waiting for EC IBF"));
}

/*
 * qnap8528led_set_status
 *
 * Set the status LED to "booting indicator mode" (flashing green/red),
 * this is done by wirint the value 5 to register 0x155, since this is a
 * write command, the register value must be ORed with 0x8000.
 */
static void qnap8528led_set_status(void) {
    /* Prepare the EC for a command */
    if (qnap8528led_ec_wait_ibf())
        return;
    grub_outb(0x88, 0x6c);

    /* Write first part of 0x155 | 0x8000 */
    if (qnap8528led_ec_wait_ibf())
        return;
    grub_outb(0x81, 0x68);

    /* Write second part of 0x155 | 0x8000 */
    if (qnap8528led_ec_wait_ibf())
        return;
    grub_outb(0x55, 0x68);

    /* Write value of 5 to the register */
    if (qnap8528led_ec_wait_ibf())
        return;
    grub_outb(0x05, 0x68);
}

GRUB_MOD_INIT(qnap8528led) {
    qnap8528led_set_status();
}

GRUB_MOD_FINI(qnap8528led) {
}
