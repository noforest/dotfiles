// GNOME refuses to resize a maximized window, so Super+right drag does nothing
// on it. dwm's monocle has no such state: the window fills the screen and any
// drag resizes it. This gives the maximize and unmaximize keys that behaviour.
// The window is sized to the work area and never marked maximized.
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// get_maximized() and the flags of unmaximize() went away in GNOME 49
function isMaximized(win) {
    return win.is_maximized ? win.is_maximized() : win.get_maximized() !== 0;
}

function unmaximize(win) {
    try {
        win.unmaximize(Meta.MaximizeFlags.BOTH);
    } catch {
        win.unmaximize();
    }
}

export default class ResizableMaximize extends Extension {
    enable() {
        this._idles = new Set();
        const mode = Shell.ActionMode.NORMAL;
        Main.wm.setCustomKeybindingHandler('maximize', mode, (_d, win) => win && this._fill(win));
        Main.wm.setCustomKeybindingHandler('unmaximize', mode, (_d, win) => win && this._restore(win));
        // A window that opens maximized (alacritty's startup_mode) is filled too
        this._created = global.display.connect('window-created', (_d, win) => {
            const id = win.connect('shown', () => {
                win.disconnect(id);
                if (isMaximized(win))
                    this._fill(win);
            });
        });
    }

    disable() {
        global.display.disconnect(this._created);
        Meta.keybindings_set_custom_handler('maximize', null);
        Meta.keybindings_set_custom_handler('unmaximize', null);
        this._idles.forEach(id => GLib.source_remove(id));
        this._idles = null;
    }

    _fill(win) {
        const area = win.get_work_area_current_monitor();
        const resize = () => win.move_resize_frame(true, area.x, area.y, area.width, area.height);
        if (!isMaximized(win)) {
            const frame = win.get_frame_rect();
            // Filling twice must not forget the size to come back to
            if (frame.width !== area.width || frame.height !== area.height)
                win._resizableMaximizeRestore = frame;
            resize();
            return;
        }
        // Its own size is the one unmaximizing gives back, nothing to remember.
        // The resize waits for the unmaximize to be through.
        unmaximize(win);
        const id = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            this._idles.delete(id);
            resize();
            return GLib.SOURCE_REMOVE;
        });
        this._idles.add(id);
    }

    _restore(win) {
        const r = win._resizableMaximizeRestore;
        delete win._resizableMaximizeRestore;
        if (isMaximized(win))
            unmaximize(win);
        else if (r)
            win.move_resize_frame(true, r.x, r.y, r.width, r.height);
    }
}
