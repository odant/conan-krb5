/* -*- mode: c; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/* kdc/t_ndr.c - tests for ndr.c */
/*
 * Copyright (C) 2021 by Red Hat, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in
 *   the documentation and/or other materials provided with the
 *   distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Unit tests for the NDR marshalling/unmarshalling in ndr.c
 */

#include "k5-int.h"
#include "kdc_util.h"

/*
 * Three S4U_DELEGATION_INFO buffers decoded from communication with AD 2019:
 *
 * - svc1/adserver.ad.test@AD.TEST to svc2/adserver.ad.test@AD.TEST
 * - svc1/adserver.ad.test@AD.TEST to longsvc/adserver.ad.test@AD.TEST
 * - svc1/adserver.ad.test@AD.TEST to svc2/adserver.ad.test@AD.TEST then
 *                                 to longsvc/adserver.ad.test@AD.TEST
 */
static uint8_t s4u_di_short[] = {
    0x01, 0x10, 0x08, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0xa0, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x2a, 0x00, 0x2c, 0x00,
    0x04, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x08, 0x00, 0x02, 0x00,
    0x16, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x00, 0x00, 0x00,
    0x73, 0x00, 0x76, 0x00, 0x63, 0x00, 0x32, 0x00, 0x2f, 0x00, 0x61, 0x00,
    0x64, 0x00, 0x73, 0x00, 0x65, 0x00, 0x72, 0x00, 0x76, 0x00, 0x65, 0x00,
    0x72, 0x00, 0x2e, 0x00, 0x61, 0x00, 0x64, 0x00, 0x2e, 0x00, 0x74, 0x00,
    0x65, 0x00, 0x73, 0x00, 0x74, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x3a, 0x00, 0x3c, 0x00, 0x0c, 0x00, 0x02, 0x00, 0x1e, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00, 0x73, 0x00, 0x76, 0x00,
    0x63, 0x00, 0x31, 0x00, 0x2f, 0x00, 0x61, 0x00, 0x64, 0x00, 0x73, 0x00,
    0x65, 0x00, 0x72, 0x00, 0x76, 0x00, 0x65, 0x00, 0x72, 0x00, 0x2e, 0x00,
    0x61, 0x00, 0x64, 0x00, 0x2e, 0x00, 0x74, 0x00, 0x65, 0x00, 0x73, 0x00,
    0x74, 0x00, 0x40, 0x00, 0x41, 0x00, 0x44, 0x00, 0x2e, 0x00, 0x54, 0x00,
    0x45, 0x00, 0x53, 0x00, 0x54, 0x00, 0x00, 0x00,
};

static uint8_t s4u_di_long[] = {
    0x01, 0x10, 0x08, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0xa8, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x30, 0x00, 0x32, 0x00,
    0x04, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x08, 0x00, 0x02, 0x00,
    0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,
    0x6c, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x67, 0x00, 0x73, 0x00, 0x76, 0x00,
    0x63, 0x00, 0x2f, 0x00, 0x61, 0x00, 0x64, 0x00, 0x73, 0x00, 0x65, 0x00,
    0x72, 0x00, 0x76, 0x00, 0x65, 0x00, 0x72, 0x00, 0x2e, 0x00, 0x61, 0x00,
    0x64, 0x00, 0x2e, 0x00, 0x74, 0x00, 0x65, 0x00, 0x73, 0x00, 0x74, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x3a, 0x00, 0x3c, 0x00, 0x0c, 0x00, 0x02, 0x00,
    0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00,
    0x73, 0x00, 0x76, 0x00, 0x63, 0x00, 0x31, 0x00, 0x2f, 0x00, 0x61, 0x00,
    0x64, 0x00, 0x73, 0x00, 0x65, 0x00, 0x72, 0x00, 0x76, 0x00, 0x65, 0x00,
    0x72, 0x00, 0x2e, 0x00, 0x61, 0x00, 0x64, 0x00, 0x2e, 0x00, 0x74, 0x00,
    0x65, 0x00, 0x73, 0x00, 0x74, 0x00, 0x40, 0x00, 0x41, 0x00, 0x44, 0x00,
    0x2e, 0x00, 0x54, 0x00, 0x45, 0x00, 0x53, 0x00, 0x54, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
};

static uint8_t s4u_di_double[] = {
    0x01, 0x10, 0x08, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0xf8, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x30, 0x00, 0x32, 0x00,
    0x04, 0x00, 0x02, 0x00, 0x02, 0x00, 0x00, 0x00, 0x08, 0x00, 0x02, 0x00,
    0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,
    0x6c, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x67, 0x00, 0x73, 0x00, 0x76, 0x00,
    0x63, 0x00, 0x2f, 0x00, 0x61, 0x00, 0x64, 0x00, 0x73, 0x00, 0x65, 0x00,
    0x72, 0x00, 0x76, 0x00, 0x65, 0x00, 0x72, 0x00, 0x2e, 0x00, 0x61, 0x00,
    0x64, 0x00, 0x2e, 0x00, 0x74, 0x00, 0x65, 0x00, 0x73, 0x00, 0x74, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x3a, 0x00, 0x3c, 0x00, 0x0c, 0x00, 0x02, 0x00,
    0x3a, 0x00, 0x3c, 0x00, 0x10, 0x00, 0x02, 0x00, 0x1e, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00, 0x73, 0x00, 0x76, 0x00,
    0x63, 0x00, 0x31, 0x00, 0x2f, 0x00, 0x61, 0x00, 0x64, 0x00, 0x73, 0x00,
    0x65, 0x00, 0x72, 0x00, 0x76, 0x00, 0x65, 0x00, 0x72, 0x00, 0x2e, 0x00,
    0x61, 0x00, 0x64, 0x00, 0x2e, 0x00, 0x74, 0x00, 0x65, 0x00, 0x73, 0x00,
    0x74, 0x00, 0x40, 0x00, 0x41, 0x00, 0x44, 0x00, 0x2e, 0x00, 0x54, 0x00,
    0x45, 0x00, 0x53, 0x00, 0x54, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00, 0x73, 0x00, 0x76, 0x00,
    0x63, 0x00, 0x32, 0x00, 0x2f, 0x00, 0x61, 0x00, 0x64, 0x00, 0x73, 0x00,
    0x65, 0x00, 0x72, 0x00, 0x76, 0x00, 0x65, 0x00, 0x72, 0x00, 0x2e, 0x00,
    0x61, 0x00, 0x64, 0x00, 0x2e, 0x00, 0x74, 0x00, 0x65, 0x00, 0x73, 0x00,
    0x74, 0x00, 0x40, 0x00, 0x41, 0x00, 0x44, 0x00, 0x2e, 0x00, 0x54, 0x00,
    0x45, 0x00, 0x53, 0x00, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

static uint8_t fuzz1[] = {
    0x01, 0x10, 0x08, 0x20, 0x20, 0x20, 0x20, 0x20, 0x24, 0x00, 0x00, 0x00,
    0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
    0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xff, 0xff, 0xff,
    0xff, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00, 0x00,
    0x20, 0x20, 0x20, 0x20
};

static uint8_t fuzz2[] = {
    0x01, 0x10, 0x08, 0x00, 0x00, 0xff, 0xff, 0xff, 0x24, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x1e, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x16, 0x00, 0x00,
    0x1e, 0x00, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x1e
};

static void
test_dec_enc(uint8_t *blob, size_t len, char *name, int fail)
{
    krb5_data data_in, data_out;
    struct pac_s4u_delegation_info *di = NULL;
    krb5_error_code ret;
    int eq;
    size_t i;

    printf("Checking blob %s...\n", name);

    data_in = make_data(blob, len);
    ret = ndr_dec_delegation_info(&data_in, &di);
    if (fail) {
        if (!ret) {
            printf("%s: unexpected decode success\n", name);
            exit(1);
        }
        printf("%s: failed as expected\n", name);
        return;
    } else if (ret) {
        printf("%s: bad decode (%d): %s\n", name, ret, strerror(ret));
        exit(1);
    }

    printf("%s, %d\n", di->proxy_target, di->transited_services_length);
    for (i = 0; i < di->transited_services_length; i++)
        printf("    %s\n", di->transited_services[i]);

    ret = ndr_enc_delegation_info(di, &data_out);
    ndr_free_delegation_info(di);
    if (ret) {
        printf("%s: bad encode (%d): %s\n", name, ret, strerror(ret));
        exit(1);
    }

    eq = data_eq(data_in, data_out);
    krb5_free_data_contents(NULL, &data_out);
    if (!eq) {
        printf("%s: re-encoding did not produce the same result\n", name);
        exit(1);
    }

    printf("%s matched\n\n", name);
}

#define RUN_TEST(blob) test_dec_enc(blob, sizeof(blob), #blob, 0)
#define RUN_TEST_FAIL(blob) test_dec_enc(blob, sizeof(blob), #blob, 1)

int
main(void)
{
    printf("Running NDR tests...\n");

    RUN_TEST(s4u_di_short);
    RUN_TEST(s4u_di_long);
    RUN_TEST(s4u_di_double);
    RUN_TEST_FAIL(fuzz1);
    RUN_TEST_FAIL(fuzz2);

    printf("Passed NDR tests\n");
    return 0;
}
