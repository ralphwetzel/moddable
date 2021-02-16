#
# Copyright (c) 2016-2021  Moddable Tech, Inc.
#
#   This file is part of the Moddable SDK Tools.
#
#   The Moddable SDK Tools is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   The Moddable SDK Tools is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with the Moddable SDK Tools.  If not, see <http://www.gnu.org/licenses/>.
#

HOST_OS := $(shell uname)

XS_GIT_VERSION ?= $(shell git -C $(MODDABLE) describe --tags --always --dirty 2> /dev/null)

PICO_ROOT ?= $(HOME)/pico
PICO_SDK_DIR ?= $(HOME)/pico/pico-sdk
PICO_GCC_ROOT ?= /usr/local

PLATFORM_DIR = $(MODDABLE)/build/devices/pico

DEBUGGER_SPEED ?= 115200
DEBUGGER_PORT ?= /dev/cu.SLAB_USBtoUART

UF2_VOLUME_NAME ?= RPI-RP2
M4_VID ?= 2e8a
M4_PID ?= 0003

ifeq ($(HOST_OS),Darwin)
	DO_COPY = cp $(BIN_DIR)/xs_pico.uf2 $(UF2_VOLUME_PATH)
	MODDABLE_TOOLS_DIR = $(BUILD_DIR)/bin/mac/release
	UF2_VOLUME_PATH = /Volumes/$(UF2_VOLUME_NAME)
	PROGRAMMING_MODE = $(PLATFORM_DIR)/config/waitForVolume $(UF2_VOLUME_PATH)
#	PROGRAMMING_MODE = $(PLATFORM_DIR)/config/programmingMode $(M4_VID) $(M4_PID) $(UF2_VOLUME_PATH)
	KILL_SERIAL_2_XSBUG = $(shell pkill serial2xsbug)

	ifeq ($(DEBUG),1)
		DO_XSBUG = open -a $(MODDABLE_TOOLS_DIR)/xsbug.app -g
		CONNECT_XSBUG=@echo "Connect to xsbug." ; serial2xsbug $(DEBUGGER_PORT) $(DEBUGGER_SPEED) 8N1
		NORESTART=-norestart
		WAIT_FOR_COPY_COMPLETE =
	else
		DO_XSBUG =
		CONNECT_XSBUG =
		NORESTART =
		WAIT_FOR_COPY_COMPLETE = $(PLATFORM_DIR)/config/waitForVolume -x $(UF2_VOLUME_PATH)
	endif
else
	DO_COPY = DESTINATION=$$(cat $(TMP_DIR)/volumename); cp $(BIN_DIR)/xs_pico.uf2 $$DESTINATION
	MODDABLE_TOOLS_DIR = $(BUILD_DIR)/bin/lin/release
	PROGRAMMING_MODE = $(PLATFORM_DIR)/config/programmingModeLinux $(M4_VID) $(M4_PID) $(UF2_VOLUME_NAME) $(TMP_DIR)/volumename
	KILL_SERIAL_2_XSBUG = $(shell pkill serial2xsbug)
	WAIT_FOR_COPY_COMPLETE = $(PLATFORM_DIR)/config/waitForVolumeLinux -x $(UF2_VOLUME_NAME) $(TMP_DIR)/volumename

	ifeq ($(DEBUG),1)
		DO_XSBUG = $(shell nohup $(MODDABLE_TOOLS_DIR)/xsbug > /dev/null 2>&1 &)
		CONNECT_XSBUG = $(PLATFORM_DIR)/config/connectToXsbugLinux $(M4_VID) $(M4_PID)
		NORESTART=-norestart
	else
		DO_XSBUG =
		CONNECT_XSBUG =
		NORESTART =
	endif
endif

HW_DEBUG_OPT = $(FP_OPTS) # -flto
HW_OPT = -O2 $(FP_OPTS) # -flto

ifeq ($(DEBUG),1)
	LIB_DIR = $(BUILD_DIR)/tmp/pico/debug/lib
else
	ifeq ($(INSTRUMENT),1)
		LIB_DIR = $(BUILD_DIR)/tmp/pico/instrument/lib
	else
		LIB_DIR = $(BUILD_DIR)/tmp/pico/release/lib
	endif
endif

ifeq ($(MAKEFLAGS_JOBS),)
	MAKEFLAGS_JOBS = --jobs 8
endif

# Assembler flags common to all targets
ASMFLAGS += -mcpu=cortex-m0
ASMFLAGS += -mthumb -mabi=aapcs
ASMFLAGS += $(FP_OPTS)

# Linker flags

LDFLAGS += \
	-mthumb						\
	-march=armv6-m				\
	-mcpu=cortex-m0plus			\
	-mthumb						\
	-Wl,--build-id=none			\
	--specs=nosys.specs			\

LDFLAGS += \
	-Wl,--wrap=sprintf			\
	-Wl,--wrap=snprintf			\
	-Wl,--wrap=vsnprintf			\
	-Wl,--wrap=__clzsi2			\
	-Wl,--wrap=__clzdi2			\
	-Wl,--wrap=__ctzsi2			\
	-Wl,--wrap=__ctzdi2			\
	-Wl,--wrap=__popcountsi2			\
	-Wl,--wrap=__popcountdi2			\
	-Wl,--wrap=__clz			\
	-Wl,--wrap=__clzl			\
	-Wl,--wrap=__clzll			\
	-Wl,--wrap=__aeabi_idiv			\
	-Wl,--wrap=__aeabi_idivmod			\
	-Wl,--wrap=__aeabi_ldivmod			\
	-Wl,--wrap=__aeabi_uidiv			\
	-Wl,--wrap=__aeabi_uidivmod			\
	-Wl,--wrap=__aeabi_uldivmod			\
	-Wl,--wrap=__aeabi_dadd			\
	-Wl,--wrap=__aeabi_ddiv			\
	-Wl,--wrap=__aeabi_dmul			\
	-Wl,--wrap=__aeabi_drsub			\
	-Wl,--wrap=__aeabi_dsub			\
	-Wl,--wrap=__aeabi_cdcmpeq			\
	-Wl,--wrap=__aeabi_cdrcmple			\
	-Wl,--wrap=__aeabi_cdcmple			\
	-Wl,--wrap=__aeabi_dcmpeq			\
	-Wl,--wrap=__aeabi_dcmplt			\
	-Wl,--wrap=__aeabi_dcmple			\
	-Wl,--wrap=__aeabi_dcmpge			\
	-Wl,--wrap=__aeabi_dcmpgt			\
	-Wl,--wrap=__aeabi_dcmpun			\
	-Wl,--wrap=__aeabi_i2d			\
	-Wl,--wrap=__aeabi_l2d			\
	-Wl,--wrap=__aeabi_ui2d			\
	-Wl,--wrap=__aeabi_ul2d			\
	-Wl,--wrap=__aeabi_d2iz			\
	-Wl,--wrap=__aeabi_d2lz			\
	-Wl,--wrap=__aeabi_d2uiz			\
	-Wl,--wrap=__aeabi_d2ulz			\
	-Wl,--wrap=__aeabi_d2f			\
	-Wl,--wrap=sqrt			\
	-Wl,--wrap=cos			\
	-Wl,--wrap=sin			\
	-Wl,--wrap=tan			\
	-Wl,--wrap=atan2			\
	-Wl,--wrap=exp			\
	-Wl,--wrap=log			\
	-Wl,--wrap=ldexp			\
	-Wl,--wrap=copysign			\
	-Wl,--wrap=trunc			\
	-Wl,--wrap=floor			\
	-Wl,--wrap=ceil			\
	-Wl,--wrap=round			\
	-Wl,--wrap=sincos			\
	-Wl,--wrap=asin			\
	-Wl,--wrap=acos			\
	-Wl,--wrap=atan			\
	-Wl,--wrap=sinh			\
	-Wl,--wrap=cosh			\
	-Wl,--wrap=tanh			\
	-Wl,--wrap=asinh			\
	-Wl,--wrap=acosh			\
	-Wl,--wrap=atanh			\
	-Wl,--wrap=exp2			\
	-Wl,--wrap=log2			\
	-Wl,--wrap=exp10			\
	-Wl,--wrap=log10			\
	-Wl,--wrap=pow			\
	-Wl,--wrap=powint			\
	-Wl,--wrap=hypot			\
	-Wl,--wrap=cbrt			\
	-Wl,--wrap=fmod			\
	-Wl,--wrap=drem			\
	-Wl,--wrap=remainder			\
	-Wl,--wrap=remquo			\
	-Wl,--wrap=expm1			\
	-Wl,--wrap=log1p			\
	-Wl,--wrap=fma			\
	-Wl,--wrap=__aeabi_lmul			\
	-Wl,--wrap=__aeabi_fadd			\
	-Wl,--wrap=__aeabi_fdiv			\
	-Wl,--wrap=__aeabi_fmul			\
	-Wl,--wrap=__aeabi_frsub			\
	-Wl,--wrap=__aeabi_fsub			\
	-Wl,--wrap=__aeabi_cfcmpeq			\
	-Wl,--wrap=__aeabi_cfrcmple			\
	-Wl,--wrap=__aeabi_cfcmple			\
	-Wl,--wrap=__aeabi_fcmpeq			\
	-Wl,--wrap=__aeabi_fcmplt			\
	-Wl,--wrap=__aeabi_fcmple			\
	-Wl,--wrap=__aeabi_fcmpge			\
	-Wl,--wrap=__aeabi_fcmpgt			\
	-Wl,--wrap=__aeabi_fcmpun			\
	-Wl,--wrap=__aeabi_i2f			\
	-Wl,--wrap=__aeabi_l2f			\
	-Wl,--wrap=__aeabi_ui2f			\
	-Wl,--wrap=__aeabi_ul2f			\
	-Wl,--wrap=__aeabi_f2iz			\
	-Wl,--wrap=__aeabi_f2lz			\
	-Wl,--wrap=__aeabi_f2uiz			\
	-Wl,--wrap=__aeabi_f2ulz			\
	-Wl,--wrap=__aeabi_f2d			\
	-Wl,--wrap=sqrtf			\
	-Wl,--wrap=cosf			\
	-Wl,--wrap=sinf			\
	-Wl,--wrap=tanf			\
	-Wl,--wrap=atan2f			\
	-Wl,--wrap=expf			\
	-Wl,--wrap=logf			\
	-Wl,--wrap=ldexpf			\
	-Wl,--wrap=copysignf			\
	-Wl,--wrap=truncf			\
	-Wl,--wrap=floorf			\
	-Wl,--wrap=ceilf			\
	-Wl,--wrap=roundf			\
	-Wl,--wrap=sincosf			\
	-Wl,--wrap=asinf			\
	-Wl,--wrap=acosf			\
	-Wl,--wrap=atanf			\
	-Wl,--wrap=sinhf			\
	-Wl,--wrap=coshf			\
	-Wl,--wrap=tanhf			\
	-Wl,--wrap=asinhf			\
	-Wl,--wrap=acoshf			\
	-Wl,--wrap=atanhf			\
	-Wl,--wrap=exp2f			\
	-Wl,--wrap=log2f			\
	-Wl,--wrap=exp10f			\
	-Wl,--wrap=log10f			\
	-Wl,--wrap=powf			\
	-Wl,--wrap=powintf			\
	-Wl,--wrap=hypotf			\
	-Wl,--wrap=cbrtf			\
	-Wl,--wrap=fmodf			\
	-Wl,--wrap=dremf			\
	-Wl,--wrap=remainderf			\
	-Wl,--wrap=remquof			\
	-Wl,--wrap=expm1f			\
	-Wl,--wrap=log1pf			\
	-Wl,--wrap=fmaf			\
	-Wl,--wrap=malloc			\
	-Wl,--wrap=calloc			\
	-Wl,--wrap=free			\
	-Wl,--wrap=memcpy			\
	-Wl,--wrap=memset			\
	-Wl,--wrap=__aeabi_memcpy			\
	-Wl,--wrap=__aeabi_memset			\
	-Wl,--wrap=__aeabi_memcpy4			\
	-Wl,--wrap=__aeabi_memset4			\
	-Wl,--wrap=__aeabi_memcpy8			\
	-Wl,--wrap=__aeabi_memset8			\
	-Wl,--script=$(LINKER_SCRIPT)			\
	-Wl,--gc-sections			\
	-Wl,--wrap=printf			\
	-Wl,--wrap=vprintf			\
	-Wl,--wrap=puts			\
	-Wl,--wrap=putchar


LIB_FILES += \
	-lc -lnosys -lm \

INC_DIRS = \
	$(PICO_SDK_DIR)/src/common/pico_stdlib/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_gpio/include	\
	$(PICO_SDK_DIR)/src/common/pico_base/include	\
	$(PICO_SDK_DIR)/src/boards/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_platform/include	\
	$(PICO_SDK_DIR)/src/rp2040/hardware_regs/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_base/include	\
	$(PICO_SDK_DIR)/src/rp2040/hardware_structs/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_claim/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_sync/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_uart/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_divider/include	\
	$(PICO_SDK_DIR)/src/common/pico_time/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_timer/include	\
	$(PICO_SDK_DIR)/src/common/pico_sync/include	\
	$(PICO_SDK_DIR)/src/common/pico_util/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_runtime/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_clocks/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_resets/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_watchdog/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_xosc/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_pll/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_vreg/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_irq/include	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_flash/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_printf/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_bootrom/include	\
	$(PICO_SDK_DIR)/src/common/pico_bit_ops/include	\
	$(PICO_SDK_DIR)/src/common/pico_divider/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_double/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_int64_ops/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_float/include	\
	$(PICO_SDK_DIR)/src/common/pico_binary_info/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_stdio/include	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_stdio_uart/include		\
	$(XS_DIR)/../modules/files/preference \
	$(XS_DIR)/../modules/base/instrumentation \
	$(XS_DIR)/../modules/base/timer \
	$(PLATFORM_DIR)	\
	$(PLATFORM_DIR)/base \
	$(PLATFORM_DIR)/config

#	$(PICO_SDK_DIR)/src/rp2_common/pico_stdio_usb/include	\
#	$(PICO_SDK_DIR)/lib/tinyusb/src		\
#	$(PICO_SDK_DIR)/lib/tinyusb/src/common		\
#	$(PICO_SDK_DIR)/lib/tinyusb/hw		\
#	$(PICO_SDK_DIR)/src/rp2_common/pico_fix/rp2040_usb_device_enumeration/include	\

XS_OBJ = \
	$(LIB_DIR)/xsHost.c.o \
	$(LIB_DIR)/xsPlatform.c.o \
	$(LIB_DIR)/xsAll.c.o \
	$(LIB_DIR)/xsAPI.c.o \
	$(LIB_DIR)/xsArguments.c.o \
	$(LIB_DIR)/xsArray.c.o \
	$(LIB_DIR)/xsAtomics.c.o \
	$(LIB_DIR)/xsBigInt.c.o \
	$(LIB_DIR)/xsBoolean.c.o \
	$(LIB_DIR)/xsCode.c.o \
	$(LIB_DIR)/xsCommon.c.o \
	$(LIB_DIR)/xsDataView.c.o \
	$(LIB_DIR)/xsDate.c.o \
	$(LIB_DIR)/xsDebug.c.o \
	$(LIB_DIR)/xsError.c.o \
	$(LIB_DIR)/xsFunction.c.o \
	$(LIB_DIR)/xsGenerator.c.o \
	$(LIB_DIR)/xsGlobal.c.o \
	$(LIB_DIR)/xsJSON.c.o \
	$(LIB_DIR)/xsLexical.c.o \
	$(LIB_DIR)/xsMapSet.c.o \
	$(LIB_DIR)/xsMarshall.c.o \
	$(LIB_DIR)/xsMath.c.o \
	$(LIB_DIR)/xsMemory.c.o \
	$(LIB_DIR)/xsModule.c.o \
	$(LIB_DIR)/xsNumber.c.o \
	$(LIB_DIR)/xsObject.c.o \
	$(LIB_DIR)/xsPromise.c.o \
	$(LIB_DIR)/xsProperty.c.o \
	$(LIB_DIR)/xsProxy.c.o \
	$(LIB_DIR)/xsRegExp.c.o \
	$(LIB_DIR)/xsRun.c.o \
	$(LIB_DIR)/xsScope.c.o \
	$(LIB_DIR)/xsScript.c.o \
	$(LIB_DIR)/xsSourceMap.c.o \
	$(LIB_DIR)/xsString.c.o \
	$(LIB_DIR)/xsSymbol.c.o \
	$(LIB_DIR)/xsSyntaxical.c.o \
	$(LIB_DIR)/xsTree.c.o \
	$(LIB_DIR)/xsType.c.o \
	$(LIB_DIR)/xsdtoa.c.o \
	$(LIB_DIR)/xsmc.c.o \
	$(LIB_DIR)/xsre.c.o

XS_DIRS = \
	$(XS_DIR)/includes \
	$(XS_DIR)/sources \
	$(XS_DIR)/platforms/pico \
	$(BUILD_DIR)/devices/pico

XS_HEADERS = \
	$(XS_DIR)/includes/xs.h \
	$(XS_DIR)/includes/xsmc.h \
	$(XS_DIR)/sources/xsAll.h \
	$(XS_DIR)/sources/xsCommon.h \
	$(XS_DIR)/platforms/pico/xsPlatform.h \
	$(XS_DIR)/platforms/pico/xsHost.h

HEADERS += $(XS_HEADERS)

PICO_OBJ = \
	$(LIB_DIR)/stdlib.c.o \
	$(LIB_DIR)/gpio.c.o \
	$(LIB_DIR)/claim.c.o \
	$(LIB_DIR)/sync.c.o \
	$(LIB_DIR)/platform.c.o \
	$(LIB_DIR)/uart.c.o \
	$(LIB_DIR)/divider.S.o \
	$(LIB_DIR)/time.c.o \
	$(LIB_DIR)/timeout_helper.c.o \
	$(LIB_DIR)/timer.c.o \
	$(LIB_DIR)/sem.c.o \
	$(LIB_DIR)/lock_core.c.o \
	$(LIB_DIR)/mutex.c.o \
	$(LIB_DIR)/critical_section.c.o \
	$(LIB_DIR)/datetime.c.o \
	$(LIB_DIR)/pheap.c.o \
	$(LIB_DIR)/queue.c.o \
	$(LIB_DIR)/runtime.c.o \
	$(LIB_DIR)/clocks.c.o \
	$(LIB_DIR)/watchdog.c.o \
	$(LIB_DIR)/xosc.c.o \
	$(LIB_DIR)/pll.c.o \
	$(LIB_DIR)/vreg.c.o \
	$(LIB_DIR)/irq.c.o \
	$(LIB_DIR)/irq_handler_chain.S.o \
	$(LIB_DIR)/printf.c.o \
	$(LIB_DIR)/bit_ops_aeabi.S.o \
	$(LIB_DIR)/bootrom.c.o \
	$(LIB_DIR)/double_aeabi.S.o \
	$(LIB_DIR)/double_init_rom.c.o \
	$(LIB_DIR)/double_math.c.o \
	$(LIB_DIR)/double_v1_rom_shim.S.o \
	$(LIB_DIR)/pico_int64_ops_aeabi.S.o \
	$(LIB_DIR)/float_aeabi.S.o \
	$(LIB_DIR)/float_init_rom.c.o \
	$(LIB_DIR)/float_math.c.o \
	$(LIB_DIR)/float_v1_rom_shim.S.o \
	$(LIB_DIR)/pico_malloc.c.o \
	$(LIB_DIR)/mem_ops_aeabi.S.o \
	$(LIB_DIR)/crt0.S.o \
	$(LIB_DIR)/binary_info.c.o \
	$(LIB_DIR)/stdio.c.o \
	$(LIB_DIR)/stdio_uart.c.o \
	$(LIB_DIR)/flash.c.o \
	$(LIB_DIR)/bs2_default_padded_checksummed.S.o \
	$(LIB_DIR)/pico_divider.S.o

#	$(LIB_DIR)/stdio_usb.c.o \
#	$(LIB_DIR)/stdio_usb_descriptors.c.o \
#	$(LIB_DIR)/dcd_rp2040.c.o \
#	$(LIB_DIR)/rp2040_usb.c.o \
#	$(LIB_DIR)/usbd.c.o \
#	$(LIB_DIR)/usbd_control.c.o \
#	$(LIB_DIR)/cdc_device.c.o \
#	$(LIB_DIR)/dfu_rt_device.c.o \
#	$(LIB_DIR)/msc_device.c.o \
#	$(LIB_DIR)/tusb.c.o \
#	$(LIB_DIR)/tusb_fifo.c.o \
#	$(LIB_DIR)/rp2040_usb_device_enumeration.c.o \
# 	$(LIB_DIR)/hardware_divider.S.o \

PICO_SRC_DIRS = \
	$(PICO_SDK_DIR)/src/rp2_common/pico_stdlib			\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_gpio		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_claim		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_sync		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_flash		\
	$(PICO_SDK_DIR)/src/rp2_common/pico_platform		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_uart		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_divider		\
	$(PICO_SDK_DIR)/src/common/pico_time				\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_timer		\
	$(PICO_SDK_DIR)/src/common/pico_sync				\
	$(PICO_SDK_DIR)/src/common/pico_util				\
	$(PICO_SDK_DIR)/src/rp2_common/pico_runtime			\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_clocks		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_watchdog	\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_xosc		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_pll			\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_vreg		\
	$(PICO_SDK_DIR)/src/rp2_common/hardware_irq			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_printf			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_bootrom			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_bit_ops			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_double			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_int64_ops		\
	$(PICO_SDK_DIR)/src/rp2_common/pico_float			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_malloc			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_mem_ops			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_standard_link	\
	$(PICO_SDK_DIR)/src/rp2_common/pico_stdio			\
	$(PICO_SDK_DIR)/src/rp2_common/pico_stdio_uart		\
#	$(PICO_SDK_DIR)/src/rp2_common/pico_stdio_usb		\
	$(PICO_SDK_DIR)/src/rp2_common/boot_stage2			\
#	$(PICO_SDK_DIR)/lib/tinyusb/src/portable/raspberrypi/rp2040		\
#	$(PICO_SDK_DIR)/lib/tinyusb/src/device				\
#	$(PICO_SDK_DIR)/lib/tinyusb/src/class/cdc			\
#	$(PICO_SDK_DIR)/lib/tinyusb/src/class/msc			\
#	$(PICO_SDK_DIR)/lib/tinyusb/src/class/dfu			\
#	$(PICO_SDK_DIR)/lib/tinyusb/src						\
#	$(PICO_SDK_DIR)/lib/tinyusb/src/common				\
#	$(PICO_SDK_DIR)/lib/tinyusb/hw						\
#	$(PICO_SDK_DIR)/src/rp2_common/pico_fix/rp2040_usb_device_enumeration	

SDK_GLUE_OBJ = \
	$(TMP_DIR)/xsmain.c.o \
	$(TMP_DIR)/debugger.c.o \
	$(TMP_DIR)/main.c.o

SDK_GLUE_DIRS = \
	$(BUILD_DIR)/devices/pico/base  \
	$(BUILD_DIR)/devices/pico/config 

OBJECTS += \
	$(PICO_OBJ)

OTHER_STUFF += \
	env_vars

TOOLS_BIN = $(PICO_GCC_ROOT)/bin
TOOLS_PREFIX = arm-none-eabi-

CC  = $(TOOLS_BIN)/$(TOOLS_PREFIX)gcc
CPP = $(TOOLS_BIN)/$(TOOLS_PREFIX)g++
# LD  = $(TOOLS_BIN)/$(TOOLS_PREFIX)gcc
LD  = $(TOOLS_BIN)/$(TOOLS_PREFIX)g++
AR  = $(TOOLS_BIN)/$(TOOLS_PREFIX)ar
OBJCOPY = $(TOOLS_BIN)/$(TOOLS_PREFIX)objcopy
OBJDUMP = $(TOOLS_BIN)/$(TOOLS_PREFIX)objdump
SIZE  = $(TOOLS_BIN)/$(TOOLS_PREFIX)size

AR_FLAGS = crs

BUILDCLUT = $(MODDABLE_TOOLS_DIR)/buildclut
COMPRESSBMF = $(MODDABLE_TOOLS_DIR)/compressbmf
RLE4ENCODE = $(MODDABLE_TOOLS_DIR)/rle4encode
MCLOCAL = $(MODDABLE_TOOLS_DIR)/mclocal
MCREZ = $(MODDABLE_TOOLS_DIR)/mcrez
PNG2BMP = $(MODDABLE_TOOLS_DIR)/png2bmp
IMAGE2CS = $(MODDABLE_TOOLS_DIR)/image2cs
WAV2MAUD = $(MODDABLE_TOOLS_DIR)/wav2maud
XSC = $(MODDABLE_TOOLS_DIR)/xsc
XSID = $(MODDABLE_TOOLS_DIR)/xsid
XSL = $(MODDABLE_TOOLS_DIR)/xsl

#	-DmxNoConsole=1
#	-DPICO_DEBUG_MALLOC=1

PICO_SDK_DEFINES= \
	-DPICO_STDIO_ENABLE_CRLF_SUPPORT=0 \
	-DPICO_STDIO_DEFAULT_CRLF=0 \
	-DPICO_DEBUG_MALLOC_LOW_WATER=0	\
	-DPICO_DEFAULT_UART_BAUD_RATE=$(DEBUGGER_SPEED) \
	-DPICO_HEAP_SIZE=0xC000

PICO_C_DEFINES= \
	$(PICO_SDK_DEFINES) \
	-DCFG_TUSB_DEBUG=0 \
	-DCFG_TUSB_MCU=OPT_MCU_RP2040 \
	-DCFG_TUSB_OS=OPT_OS_PICO \
	-DPICO_BIT_OPS_PICO=1	\
	-DPICO_BOARD=\"pico\"	\
	-DPICO_BUILD=1	\
	-DPICO_COPY_TO_RAM=0	\
	-DPICO_CXX_ENABLE_EXCEPTIONS=0	\
	-DPICO_DIVIDER_HARDWARE=1	\
	-DPICO_DOUBLE_PICO=1	\
	-DPICO_FLOAT_PICO=1	\
	-DPICO_INT64_OPS_PICO=1	\
	-DPICO_MEM_OPS_PICO=1	\
	-DPICO_NO_FLASH=0	\
	-DPICO_NO_HARDWARE=0	\
	-DPICO_ON_DEVICE=1	\
	-DPICO_PRINTF_PICO=1	\
	-DPICO_PROGRAM_URL=\"https://github.com/Moddable-OpenSource\"	\
	-DPICO_STDIO_UART=1	\
	-DPICO_TARGET_NAME=\"$(NAME)\"	\
	-DPICO_USE_BLOCKED_RAM=0

#	-DPICO_STDIO_USB=1	\

C_DEFINES = \
	$(PICO_C_DEFINES) \
	$(NET_CONFIG_FLAGS) \
	-DmxUseDefaultSharedChunks=1 \
	-DmxRun=1 \
	-DkCommodettoBitmapFormat=$(DISPLAY) \
	-DkPocoRotation=$(ROTATION) \
	-DMODGCC=1

#	--sysroot=$(NRF52_GCC_ROOT)/arm-none-eabi 

C_FLAGS=\
	-c	\
	-std=gnu11 \
	-march=armv6-m	\
	-mcpu=cortex-m0plus	\
	-mthumb	\
	-ffunction-sections -fdata-sections	\

x_C_FLAGS=  -fno-strict-aliasing \
	-fno-common \
	-fomit-frame-pointer \
	-fno-dwarf2-cfi-asm \
	-fno-builtin \
	-gdwarf-3 \
	-gpubnames

ifeq ($(DEBUG),1)
	C_DEFINES += \
		-DDEBUG=1 \
		-DmxDebug=1 \
		-g3 \
		-Os
	C_FLAGS += $(HW_DEBUG_OPT)
	ASM_FLAGS += $(HW_DEBUG_OPT)
else
	C_DEFINES += \
		-DNDEBUG	\
		-Os
	C_FLAGS += $(HW_OPT)
	ASM_FLAGS += $(HW_OPT)
endif
ifeq ($(INSTRUMENT),1)
	C_DEFINES += -DMODINSTRUMENTATION=1 -DmxInstrument=1
endif

cr := '\n'
sp :=  
sp += 
qs = $(subst ?,\$(sp),$1)
C_INCLUDES += $(DIRECTORIES)
C_INCLUDES += $(foreach dir,$(INC_DIRS) $(SDK_GLUE_DIRS) $(XS_DIRS) $(LIB_DIR) $(TMP_DIR),-I$(call qs,$(dir)))


xx_C_FLAGS +=  \
	-fmessage-length=0 \
	-fno-diagnostics-show-caret \
	-mcpu=$(HWCPU) \
	-mlittle-endian \
	-mfloat-abi=hard \
	-mfpu=fpv4-sp-d16 \
	-mthumb	\
	-mthumb-interwork	\
	-mtp=soft \
	-munaligned-access \
	-nostdinc

# Nordic example apps are built with -fshort-enums
# C_FLAGS := -fshort-enums $(C_FLAGS)
# C_DEFINES := -fshort-enums $(C_DEFINES)

C_FLAGS_NODATASECTION = $(C_FLAGS)

LINKER_SCRIPT := $(PLATFORM_DIR)/config/xsproj.ld

# Utility functions
git_description = $(shell git -C  $(1) describe --tags --always --dirty 2>/dev/null)
SRC_GIT_VERSION = $(call git_description,$(PICO_SDK_DIR)/sources)
ESP_GIT_VERSION = $(call git_description,$(ARDUINO_ROOT))
time_string = $(shell perl -e 'use POSIX qw(strftime); print strftime($(1), localtime());')
BUILD_DATE = $(call time_string,"%Y-%m-%d")
BUILD_TIME = $(call time_string,"%H:%M:%S")
MEM_USAGE = \
  'while (<>) { \
      $$r += $$1 if /^\.(?:data|rodata|bss)\s+(\d+)/;\
		  $$f += $$1 if /^\.(?:irom0\.text|text|data|rodata)\s+(\d+)/;\
	 }\
	 print "\# Memory usage\n";\
	 print sprintf("\#  %-6s %6d bytes\n" x 2 ."\n", "Ram:", $$r, "Flash:", $$f);'

VPATH += $(PICO_SRC_DIRS) $(SDK_GLUE_DIRS) $(XS_DIRS)

.PHONY: all	
.SUFFIXES:
%.d:
.PRECIOUS: %.d %.o

all: precursor $(BIN_DIR)/xs_pico.uf2
	$(KILL_SERIAL_2_XSBUG)
	$(PROGRAMMING_MODE)
	$(DO_XSBUG)
	@echo Copying: $(BIN_DIR)/xs_pico.elf to $(UF2_VOLUME_NAME)
	$(DO_COPY)
	$(WAIT_FOR_COPY_COMPLETE)
	$(CONNECT_XSBUG)
#	$(CONNECT_XSBUG) $(NORESTART)

deploy: precursor $(BIN_DIR)/xs_pico.uf2
	$(KILL_SERIAL_2_XSBUG)
	$(PROGRAMMING_MODE)
	@echo Copying: $(BIN_DIR)/xs_pico.elf to $(UF2_VOLUME_NAME)
	$(DO_COPY)
	$(WAIT_FOR_COPY_COMPLETE)

build: precursor $(BIN_DIR)/xs_pico.uf2
	@echo Target built: $(BIN_DIR)/xs_pico.uf2

precursor: $(TMP_DIR) $(LIB_DIR) $(OTHER_STUFF) $(BIN_DIR)/xs_pico.elf

env_vars:
ifndef PICO_SDK_DIR
	$(error PICO_SDK_DIR environment variable must be defined! See https://github.com/Moddable-OpenSource/moddable/blob/public/documentation/devices/ for details.)
endif

clean:
	echo "# Clean project"
	-rm -rf $(BIN_DIR) 2>/dev/null
	-rm -rf $(TMP_DIR) 2>/dev/null
	-rm -rf $(LIB_DIR) 2>/dev/null

allclean:
	@echo "# Cleaning all pico"
	@echo "# rm $(MODDABLE)/build/bin/pico"
	-rm -rf $(MODDABLE)/build/bin/pico
	@echo "# rm $(MODDABLE)/build/tmp/pico"
	-rm -rf $(MODDABLE)/build/tmp/pico

UF2CONV = $(MODDABLE)/build/devices/pico/config/elf2uf2

$(BIN_DIR)/xs_pico.uf2: $(BIN_DIR)/xs_pico.elf
	@echo Making: $(BIN_DIR)/xs_pico.uf2 from xs_pico.elf
	$(UF2CONV) $(BIN_DIR)/xs_pico.elf $(BIN_DIR)/xs_pico.uf2

xsbug:
	$(KILL_SERIAL_2_XSBUG)
	$(DO_XSBUG)
	$(CONNECT_XSBUG)

$(TMP_DIR):
	@echo "TMP_DIR"
	mkdir -p $(TMP_DIR)

$(LIB_DIR):
	mkdir -p $(LIB_DIR)
	echo "typedef struct { const char *date, *time, *src_version, *env_version;} _tBuildInfo; extern _tBuildInfo _BuildInfo;" > $(LIB_DIR)/buildinfo.h
	
FINAL_LINK_OBJ:=\
	$(XS_OBJ) \
	$(SDK_GLUE_OBJ) \
	$(TMP_DIR)/mc.xs.c.o $(TMP_DIR)/mc.resources.c.o \
	$(OBJECTS) \
	$(LIB_DIR)/buildinfo.c.o

ekoFiles = $(foreach fil,$(FINAL_LINK_OBJ),$(shell echo '$(strip $(fil))' >> $(BIN_DIR)/xs_pico.ind1))

$(BIN_DIR)/xs_pico.ind: $(FINAL_LINK_OBJ)
	@echo "# creating xs_pico.ind"
#	 @echo "# FINAL LINK OBJ: $(FINAL_LINK_OBJ)"
	@rm -f $(BIN_DIR)/xs_pico.ind
#	@echo $(ekoFiles)
	$(ekoFiles)
	@mv $(BIN_DIR)/xs_pico.ind1 $(BIN_DIR)/xs_pico.ind

$(BIN_DIR)/xs_pico.elf: $(FINAL_LINK_OBJ)
	@echo "# creating xs_pico.elf"
#	 @echo "# FINAL LINK OBJ: $(FINAL_LINK_OBJ)"
	@rm -f $(BIN_DIR)/xs_pico.elf
	@echo "# link to .elf file"
	$(LD) $(LDFLAGS) $(FINAL_LINK_OBJ) $(LIB_FILES) -o $@
	@echo "# make .dis file"
	$(OBJDUMP) -h $(BIN_DIR)/xs_pico.elf > $(BIN_DIR)/xs_pico.dis
	$(OBJDUMP) -d $(BIN_DIR)/xs_pico.elf >> $(BIN_DIR)/xs_pico.dis

$(LIB_DIR)/buildinfo.c.o: $(SDK_GLUE_OBJ) $(XS_OBJ) $(TMP_DIR)/mc.xs.c.o $(TMP_DIR)/mc.resources.c.o $(OBJECTS)
	@echo "# buildinfo"
	echo '#include "buildinfo.h"' > $(LIB_DIR)/buildinfo.c
	echo '_tBuildInfo _BuildInfo = {"$(BUILD_DATE)","$(BUILD_TIME)","$(SRC_GIT_VERSION)","$(ESP_GIT_VERSION)"};' >> $(LIB_DIR)/buildinfo.c
	$(CC) $(C_FLAGS) $(C_INCLUDES) $(C_DEFINES) $(LIB_DIR)/buildinfo.c -o $@

$(XS_OBJ): $(XS_HEADERS)
$(LIB_DIR)/xs%.c.o: xs%.c
	@echo "# library xs:" $(<F)
	$(CC) $(C_FLAGS) $(C_INCLUDES) $(C_DEFINES) $< -o $@

$(LIB_DIR)/%.c.o: %.c
	@echo "# library: " $(<F)
	$(CC) $(C_FLAGS) $(C_INCLUDES) $(C_DEFINES) $< -o $@

$(LIB_DIR)/%.S.o %.s.o: %.S
	@echo "# asm " $(<F)
	$(CC) -c -x assembler-with-cpp $(ASMFLAGS) $(C_INCLUDES) $< -o $@

$(TMP_DIR)/%.c.o: %.c
	@echo "# application: " $(<F)
	$(CC) $(C_FLAGS) $(C_INCLUDES) $(C_DEFINES) $< -o $@

$(TMP_DIR)/mc.%.c.o: $(TMP_DIR)/mc.%.c
	@echo "# cc" $(<F) "(slots in flash)"
	$(CC) $< $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS_NODATASECTION) -o $@

$(TMP_DIR)/mc.xs.c: $(MODULES) $(MANIFEST)
	@echo "# xsl modules"
	$(XSL) -b $(MODULES_DIR) -o $(TMP_DIR) $(PRELOADS) $(STRIPS) $(CREATION) $(MODULES)

$(TMP_DIR)/mc.resources.c: $(RESOURCES) $(MANIFEST)
	@echo "# mcrez resources"
	$(MCREZ) $(RESOURCES) -o $(TMP_DIR) -p pico -r mc.resources.c

# $(LIB_DIR)/hardware_divider.S.o: $(PICO_SDK_DIR)/src/rp2_common/hardware_divider/divider.S
# 	@echo "# asm (special) " $(<F)
# 	$(CC) -c -x assembler-with-cpp $(ASMFLAGS) $(C_INCLUDES) $< -o $@

$(LIB_DIR)/pico_divider.S.o: $(PICO_SDK_DIR)/src/rp2_common/pico_divider/divider.S
	@echo "# asm  (special)" $(<F)
	$(CC) -c -x assembler-with-cpp $(ASMFLAGS) $(C_INCLUDES) $< -o $@

MAKEFLAGS += $(MAKEFLAGS_JOBS)
ifneq ($(VERBOSE),1)
MAKEFLAGS += --silent
endif

