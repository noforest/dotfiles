/*
 * LD_PRELOAD shim: makes a Wayland client bind wl_seat at version 9 at most.
 *
 * From wl_seat version 10 the compositor may repeat held keys itself, and
 * mutter 50 and GTK 4 both use that. mutter 50 gets it wrong: a key pressed
 * while another one is still held is sent once and never repeated
 * (https://gitlab.gnome.org/GNOME/mutter/-/issues/4675, fixed in mutter 51).
 * Bound at version 9, GTK repeats keys itself, as it did before, and that
 * code handles the case.
 *
 * wl_registry_bind() is an inline wrapper around the variadic
 * wl_proxy_marshal_flags(), so that is the symbol to interpose. A variadic
 * call cannot be forwarded portably; this relies on the x86-64 and aarch64
 * calling conventions, where every Wayland argument (integers, fixed-point
 * and pointers, never floating point) travels as one machine word. Wayland
 * requests have at most 20 arguments.
 *
 * Built and wired to ghostty by `dot gnome-settings`.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>

struct wl_proxy;
/* Only the head of the real struct is needed. */
struct wl_interface { const char *name; int version; };

#define MAX_SEAT_VERSION 9

typedef struct wl_proxy *(*marshal_flags_fn)(struct wl_proxy *, uint32_t,
                                             const struct wl_interface *,
                                             uint32_t, uint32_t, ...);

struct wl_proxy *
wl_proxy_marshal_flags(struct wl_proxy *proxy, uint32_t opcode,
                       const struct wl_interface *interface, uint32_t version,
                       uint32_t flags, ...)
{
    static marshal_flags_fn real;
    uintptr_t a[20];
    va_list ap;
    int i;

    if (!real)
        real = (marshal_flags_fn)dlsym(RTLD_NEXT, "wl_proxy_marshal_flags");

    va_start(ap, flags);
    for (i = 0; i < 20; i++)
        a[i] = va_arg(ap, uintptr_t);
    va_end(ap);

    /* wl_registry.bind(name, interface name, version, new_id): the version
     * is passed twice, as the proxy version and as the third argument. */
    if (interface && interface->name && strcmp(interface->name, "wl_seat") == 0
        && version > MAX_SEAT_VERSION) {
        version = MAX_SEAT_VERSION;
        a[2] = MAX_SEAT_VERSION;
    }

    return real(proxy, opcode, interface, version, flags,
                a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9],
                a[10], a[11], a[12], a[13], a[14], a[15], a[16], a[17], a[18],
                a[19]);
}
