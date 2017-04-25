/**
 * May need to permanently disable automounting with:
 *
 * $ gsettings set org.gnome.desktop.media-handling automount false
 */

using GPhoto;

public errordomain GPhotoError {
    LIBRARY
}

public class App : Object {

    private Context context;
    private Camera camera;
    private Result result;

    extern void capture_to_file (Camera camera, Context context, string filename);

    public App () {
        result = Camera.create (out camera);
        if (result != Result.OK) {
            critical (result.to_full_string ());
        }

        context = new Context ();
        result = camera.init (context);
        if (result != Result.OK) {
            critical (result.to_full_string ());
        }
    }

    ~App () {
        camera.exit (context);
    }

    public void info () {
        Result ret;
        PortInfo port_info;
        CameraAbilities abilities;
        //CameraStorageInformation storage_info;

        ret = camera.get_port_info (out port_info);
        if (ret != Result.OK) {
            critical (ret.to_full_string ());
            return;
        }

        string name;
        string path;
        string library_filename;

        port_info.get_name (out name);
        port_info.get_path (out path);

        stdout.printf (" name: %s\n", name);
        stdout.printf (" path: %s\n", path);

        ret = camera.get_abilities (out abilities);
        if (ret != Result.OK) {
            critical (ret.to_full_string ());
            return;
        }
    }

    public Result run () {
        if (result != Result.OK) {
            return result;
        }

        for (var i = 0; i < 10; i++) {
            var filename = "shot-%04d.nef".printf (i);
            stdout.printf ("Capturing to file %s\n", filename);
            try {
                capture ("", filename);
            } catch (Error e) {
                critical (e.message);
            }
        }

        return Result.OK;
    }

    private void capture (string folder, string filename) throws Error {
        capture_to_file (camera, context, filename);

/*
 *        CameraFile file;
 *        var dest_file = File.new_for_path (filename);
 *
 *        var fd = Posix.creat (dest_file.get_path (), 0640);
 *        if (fd < 0) {
 *            throw new IOError.FAILED("[%d] Error creating file %s: %m",
 *                GLib.errno, dest_file.get_path());
 *        }
 *
 *        Result res = CameraFile.create_from_fd (out file, fd);
 *        if (res != Result.OK) {
 *            Posix.close (fd);
 *            throw new GPhotoError.LIBRARY ("[%d] Error allocating camera file: %s",
 *                (int) res, res.as_string ());
 *        }
 *
 *        res = camera.get_file (folder, filename, CameraFileType.NORMAL, file, context);
 *        if (res != Result.OK) {
 *            Posix.close (fd);
 *            throw new GPhotoError.LIBRARY("[%d] Error retrieving file object for %s/%s: %s",
 *                (int) res, folder, filename, res.as_string());
 *        }
 *
 *        Posix.close (fd);
 */
    }

    public static int main (string[] args) {
        var app = new App ();
        app.info ();
        var ret = app.run ();

        if (ret != Result.OK) {
            return -1;
        }

        return 0;
    }
}
