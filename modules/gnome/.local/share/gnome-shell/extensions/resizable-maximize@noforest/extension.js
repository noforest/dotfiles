// GNOME refuses to resize a maximized window, so Super+right drag does nothing
// on it. dwm's monocle has no such state: the window fills the screen and any
// drag resizes it. This gives the maximize and unmaximize keys that behaviour.
// The window is sized to the work area and never marked maximized.
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// get_maximized() and the flags of unmaximize() went away in GNOME 49
function isMaximized(win) {
    return win.is_maximized ? win.is_maximized() : win.get_maximized() !== 0;
}

function unmaximize(win) {
    if (win.is_maximized)
        win.unmaximize();
    else
        win.unmaximize(Meta.MaximizeFlags.BOTH);
}

function isTerminal(win) {
    return ['com.mitchellh.ghostty', 'Alacritty'].includes(win.get_wm_class());
}

function isFirefox(win) {
    return win.get_window_type() === Meta.WindowType.NORMAL && /^firefox/i.test(win.get_wm_class() ?? '');
}

export default class ResizableMaximize extends Extension {
    enable() {
        this._pending = new Map();
        const mode = Shell.ActionMode.NORMAL;
        Main.wm.setCustomKeybindingHandler('maximize', mode, (_d, win) => win && this._fill(win));
        Main.wm.setCustomKeybindingHandler('unmaximize', mode, (_d, win) => win && this._restore(win));
        // ghostty and alacritty open maximized (maximize, startup_mode) and are
        // filled at once. So is
        // Firefox, which has no setting to start maximized: only its first
        // window, the later ones (picture-in-picture, library, devtools) keep
        // their size. The others keep the maximized state they ask for until
        // Super+M.
        this._created = global.display.connect('window-created', (_d, win) => {
            const id = win.connect('shown', () => {
                win.disconnect(id);
                if (isTerminal(win) && isMaximized(win))
                    this._fill(win);
                else if (isFirefox(win) && !global.display.list_all_windows().some(w => w !== win && isFirefox(w)))
                    this._fill(win);
            });
        });
    }

    disable() {
        global.display.disconnect(this._created);
        Meta.keybindings_set_custom_handler('maximize', null);
        Meta.keybindings_set_custom_handler('unmaximize', null);
        this._pending.forEach((id, win) => win.disconnect(id));
        this._pending = null;
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
        // The resize waits for the window to have taken that size: sent right
        // behind the unmaximize, it left Firefox drawn off its own frame.
        if (this._pending.has(win))
            return;
        const id = win.connect('size-changed', () => {
            if (isMaximized(win))
                return;
            win.disconnect(id);
            this._pending.delete(win);
            resize();
        });
        this._pending.set(win, id);
        unmaximize(win);
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
