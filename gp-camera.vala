/**
 * To compile:
 *   valac --pkg libgphoto2 --vapidir=. --includedir=. -X -I. gp-camera.vala gphoto.h
 */

using GPhoto;

public errordomain GPhotoError {
    ABILITIES,
    CONFIG,
    GENERAL,
    LIBRARY,
    PORT_INFO
}

public class App : Object {

    private Context context;
    private Camera camera;

    public App () {
        Result ret;

        ret = Camera.create (out camera);
        if (ret != Result.OK) {
            critical (ret.to_full_string ());
        }

        context = new Context ();
        ret = camera.init (context);
        if (ret != Result.OK) {
            critical (ret.to_full_string ());
        }
    }

    ~App () {
        camera.exit (context);
    }

    public void print_port_list () throws GPhotoError {
        Result ret;
        PortInfoList list;
        string name, path;

        ret = PortInfoList.create (out list);
        list.load ();
        if (ret != Result.OK) {
            critical (ret.to_full_string ());
        }

        stdout.printf ("Camera List (incomplete)\n");
        stdout.printf (" %2d cameras connected\n", list.count ());
        for (int i = 0; i < list.count (); i++) {
            PortInfo port_info;
            list.get_info (i, out port_info);
            port_info.get_name (out name);
            port_info.get_path (out path);
            stdout.printf (" %2d %s - %s\n", i, name, path);
        }
        stdout.printf ("\n");
    }

    public void print_port_info () throws GPhotoError {
        Result ret;
        PortInfo port_info;
        string name;
        string path;
        //string library_filename;

        ret = camera.get_port_info (out port_info);
        if (ret != Result.OK) {
            throw new GPhotoError.PORT_INFO (ret.to_full_string ());
        }

        ret = (Result) port_info.get_name (out name);
        if (ret != Result.OK) {
            throw new GPhotoError.PORT_INFO (ret.to_full_string ());
        }

        ret = (Result) port_info.get_path (out path);
        if (ret != Result.OK) {
            throw new GPhotoError.PORT_INFO (ret.to_full_string ());
        }

        //ret = (Result) port_info.get_library_filename (out library_filename);
        //if (ret != Result.OK) {
            //throw new GPhotoError.PORT_INFO (ret.to_full_string ());
        //}


        stdout.printf ("Port Info (incomplete)\n");
        stdout.printf (" name: %s\n", name);
        stdout.printf (" path: %s\n", path);
        //stdout.printf (" lib:  %s\n", library_filename);
        stdout.printf ("\n");
    }

    public void print_abilities () throws GPhotoError {
        Result ret;
        CameraAbilities abilities;

        ret = camera.get_abilities (out abilities);
        if (ret != Result.OK) {
            throw new GPhotoError.ABILITIES (ret.to_full_string ());
        }

        stdout.printf ("Abilities (incomplete)\n");
        stdout.printf (" model:    %s\n", abilities.model);
        stdout.printf (" status:   %d\n", abilities.status);
        stdout.printf (" speed:    %s\n", abilities.speed);
        stdout.printf (" vendor:   0x%04X\n", abilities.usb_vendor);
        stdout.printf (" product:  0x%04X\n", abilities.usb_product);
        stdout.printf (" class:    %d\n", abilities.usb_class);
        stdout.printf (" protocol: %d\n", abilities.usb_protocol);
        stdout.printf ("\n");
    }

    public void print_misc () throws GPhotoError {
        Result ret;
        CameraText summary;
        //CameraText manual;
        CameraText about;

        ret = camera.get_summary (out summary, context);
        if (ret != Result.OK) {
            throw new GPhotoError.GENERAL (ret.to_full_string ());
        }

        //ret = camera.get_manual (out manual, context);
        //if (ret != Result.OK) {
            //throw new GPhotoError.GENERAL (ret.to_full_string ());
        //}

        ret = camera.get_about (out about, context);
        if (ret != Result.OK) {
            throw new GPhotoError.GENERAL (ret.to_full_string ());
        }

        stdout.printf ("Miscellaneous (incomplete)\n");
        stdout.printf (" summary: %s\n", (string) summary.text);
        //stdout.printf (" manual:  %s\n", (string) manual.text);
        stdout.printf (" about:   %s\n", (string) about.text);
        stdout.printf ("\n");
    }

    public void print_config () throws GPhotoError {
        Result ret;
        CameraWidget window;
        string name;

        ret = camera.get_config (out window, context);
        if (ret != Result.OK) {
            throw new GPhotoError.CONFIG (ret.to_full_string ());
        }

        window.get_name (out name);
        stdout.printf ("Camera Config (incomplete)\n");
        stdout.printf (" name:           %s\n", name);
        stdout.printf (" child count:    %d\n", window.count_children ());

        stdout.printf ("\n");
        display_widgets (window, "");
    }

    public int print_widget (CameraWidget widget, string name) {
        string label;
        CameraWidgetType type;
        int ret;

        ret = widget.get_type (out type);
        if (ret != Result.OK) {
            return ret;
        }

        ret = widget.get_label (out label);
        if (ret != Result.OK) {
            return ret;
        }

        stdout.printf ("Label: %s\n", label);

        switch (type) {
            case CameraWidgetType.TEXT:
                void *value;
                string text;
                ret = widget.get_value (out value);
                if (ret != Result.OK) {
                    context.error ("Failed to retrieve value of text widget %s.", name);
                    break;
                }
                text = (string) value;
                stdout.printf ("Type: TEXT\n");
                stdout.printf ("Current: %s\n", text);
                break;
            case CameraWidgetType.RANGE:
                void *value;
                float[] ary;
                float f, t, b, s;
                ret = widget.get_range (out b, out t, out s);
                if (ret != Result.OK) {
                    context.error ("Failed to retrieve values of range widget %s.", name);
                    break;
                }
                ret = widget.get_value (out value);
                if (ret != Result.OK) {
                    context.error ("Failed to retrieve values of range widget %s.", name);
                    break;
                }
                ary = (float[]) value;
                f = ary[0];
                stdout.printf ("Type: RANGE\n");
                stdout.printf ("Current: %g\n", f);
                stdout.printf ("Bottom: %g\n", b);
                stdout.printf ("Top: %g\n", t);
                stdout.printf ("Step: %g\n", s);
                break;
            case CameraWidgetType.TOGGLE:
                void *value;
                uint8 t;
                ret = widget.get_value (out value);
                if (ret != Result.OK) {
                    context.error ("Failed to retrieve values of toggle widget %s.", name);
                    break;
                }
                t = (uint8) value;
                stdout.printf ("Type: TOGGLE\n");
                stdout.printf ("Current: %d\n", t);
                break;
            case CameraWidgetType.DATE:
                void *value;
                long t;
                ret = widget.get_value (out value);
                if (ret != Result.OK) {
                    context.error ("Failed to retrieve values of date widget %s.", name);
                    break;
                }
                t = (long) value;
                Time time = Time.local ((time_t) t);
                stdout.printf ("Type: DATE\n");
                stdout.printf ("Current: %ld\n", t);
                stdout.printf ("Printable: %s\n", time.to_string ());
                stdout.printf ("Help: %s\n", "Use 'now' as the current time when setting.\n");
                break;
            case CameraWidgetType.MENU:
            case CameraWidgetType.RADIO:
                int n;
                string current;
                void *value;
                ret = widget.get_value (out value);
                if (ret != Result.OK) {
                    context.error ("Failed to retrieve values of radio widget %s.", name);
                    break;
                }
                n = widget.count_choices ();
                if (type == CameraWidgetType.MENU) {
                    stdout.printf ("Type: MENU\n");
                } else {
                    stdout.printf ("Type: RADIO\n");
                }
                current = (string) value;
                stdout.printf ("Current: %s\n", current);
                for (int i = 0; i < n; i++) {
                    string choice;
                    ret = widget.get_choice (i, out choice);
                    if (ret != Result.OK) {
                        continue;
                    }
                    stdout.printf ("Choice: %d %s\n", i, choice);
                }
                break;
            case CameraWidgetType.WINDOW:
            case CameraWidgetType.SECTION:
            case CameraWidgetType.BUTTON:
                break;
        }

        return Result.OK;
    }

    private void display_widgets (CameraWidget widget, string prefix) {
        int n, ret;
        string name, label;
        string use_label;
        string new_prefix;
        CameraWidgetType type;

        widget.get_name (out name);
        widget.get_label (out label);
        widget.get_type (out type);

        if (name.length > 0) {
            use_label = name;
        } else {
            use_label = label;
        }

        n = widget.count_children ();
        new_prefix = "%s/%s".printf (prefix, use_label);

        if ((type != CameraWidgetType.WINDOW) && (type != CameraWidgetType.SECTION)) {
            stdout.printf ("%s\n", new_prefix);
            print_widget (widget, new_prefix);
        }

        for (int i = 0; i < n; i++) {
            CameraWidget child;
            ret = widget.get_child (i, out child);
            if (ret != Result.OK) {
                continue;
            }
            display_widgets (child, new_prefix);
        }
    }

    public static int main (string[] args) {
        var app = new App ();

        try {
            app.print_port_list ();
            app.print_port_info ();
            app.print_abilities ();
            //app.print_misc ();
            app.print_config ();
        } catch (GPhotoError e) {
            error (e.message);
        }

        return 0;
    }
}
