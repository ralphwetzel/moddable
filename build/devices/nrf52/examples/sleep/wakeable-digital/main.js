/*
 * Copyright (c) 2016-2020  Moddable Tech, Inc.
 *
 *   This file is part of the Moddable SDK.
 * 
 *   This work is licensed under the
 *       Creative Commons Attribution 4.0 International License.
 *   To view a copy of this license, visit
 *       <http://creativecommons.org/licenses/by/4.0>.
 *   or send a letter to Creative Commons, PO Box 1866,
 *   Mountain View, CA 94042, USA.
 *
 */
/*
	This application demonstrates how to use the WakeableDigital object to determine if the device woke up from deep sleep due to hard reset or another trigger.
	The nRF52 only exits deep sleep from a pre-configured digital, analog, or NFC trigger. Also from hard reset.
	Upon wakeup the LED blinks if wakeup was due to a pre-configured trigger.
	The device is woken up from a digital input or hard reset.
	The application turns on the LED while running and turns off the LED when asleep.
	Press the button connected to the digital input pin or the reset button to wakeup the device.
*/

import WakeableDigital from "builtin/wakeabledigital";
import Digital from "pins/digital";
import {Sleep} from "sleep";
import Timer from "timer";
import config from "mc/config";

const wakeup_pin = 22;
const led_pin = config.led1_pin;
const ON = 1;
const OFF = 0;

// Turn on LED upon wakeup
Digital.write(led_pin, ON);

//let wakeable = new WakeableDigital({ pin: "RST" });
let wakeable = new WakeableDigital({ pin: wakeup_pin });
if (wakeable.read()) {
	blink();
}

let count = 3;
Timer.repeat(id => {
	if (0 == count) {
		Timer.clear(id);
		
		// turn off led while asleep
		Digital.write(led_pin, OFF);
		
		Sleep.deep();
	}
	--count;
}, 1000);

function blink()
{
	for (let i = 0; i < 5; ++i) {
		Digital.write(led_pin, ON);
		Timer.delay(200);
		Digital.write(led_pin, OFF);
		Timer.delay(200);
	}
}
