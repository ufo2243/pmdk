# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2018, Intel Corporation
#
#
# libpmempool_map_flog/TEST1 -- test for checking map and flog
#

. ..\unittest\unittest.ps1

require_test_type medium
require_fs_type any

setup

$POOL = "$DIR\file.pool"
$LOG = "out${Env:UNITTEST_NUM}.log"
$LOG_TEMP = "out${Env:UNITTEST_NUM}_part.log"
rm $LOG -Force -ea si
touch $LOG
rm $LOG_TEMP -Force -ea si
touch $LOG_TEMP

$EXE = "$Env:EXE_DIR\libpmempool_test$Env:EXESUFFIX"

$map_err = @{ "Initial"="0"
              "Error"="4"
              "Zeroed"="8"
              "Normal"="C" }

$ent_val = 6

foreach ($field in ("Zeroed", "Error", "Initial", "Normal")) {
    expect_normal_exit $BTTCREATE $POOL

    $x = $map_err[$field]
    for ($i=0; $i -lt $ent_val; $i++) {
        $spcmd = "bttdevice.arena.btt_map($i)=0x${x}000000${i}"
        echo "${field}: $spcmd" | out-file -append -encoding ascii -literalpath $LOG_TEMP
        &$PMEMSPOIL $POOL $spcmd
    }

    # duplicated entry
    $spcmd = "bttdevice.arena.btt_map(6)=0x${x}0000003"
    echo "${field}: $spcmd" | out-file -append -encoding ascii -literalpath $LOG_TEMP
    &$PMEMSPOIL $POOL $spcmd

    # lba number is higher then internal nlba
    $spcmd = "bttdevice.arena.btt_map(2)=0x${x}000FFFF"
    echo "${field}: $spcmd" | out-file -append -encoding ascii -literalpath $LOG_TEMP
    &$PMEMSPOIL $POOL $spcmd

    expect_normal_exit $EXE -r 1 -t btt -a 1 $POOL
    cat -Encoding Ascii $LOG | out-file -append -encoding ascii -literalpath $LOG_TEMP
}

mv -Force $LOG_TEMP $LOG
check_file $POOL

check
pass
