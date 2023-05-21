#include <stdio.h>
#include </usr/include/security/pam_appl.h>
#include </usr/include/security/pam_misc.h>

static struct pam_conv conv = {
    misc_conv,
    NULL
};

int main(int argc, char **argv) {
    pam_handle_t *pamh = NULL;
    int rval;
    const char *user = "nobody";

    if(argc == 2) {
        user = argv[1];
    }

    if(argc != 2) {
        fprintf(stderr, "Usage: check_user [username]\n");
        exit(1);
    }

    rval = pam_start("check", user, &conv, &pamh);

    if (rval == PAM_SUCCESS) {
        rval = pam_authenticate(pamh, 0);
        printf("authenticate error code: ", pam_strerror(pamh, rval), '\n');
    }

    if (rval == PAM_SUCCESS) {
        rval = pam_acct_mgmt(pamh, 0);
    }

    if (rval == PAM_SUCCESS) {
        fprintf(stdout, "Auth\n");
    } else {
        fprintf(stdout, "Not Auth\n");
    }

    printf("error code: %s\n", pam_strerror(pamh, rval));

    if (pam_end(pamh,rval) != PAM_SUCCESS) {
        pamh = NULL;
        fprintf(stderr, "check_user: failed to release authenticator\n");
        exit(1);
    }

    return ( rval == PAM_SUCCESS ? 0:1 );
}
