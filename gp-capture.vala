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

    public int frames { get; set; default = 1; }
    public int interval { get; set; default = 0; }

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

    private int save_file (string folder, string filename, CameraFileType type) {
        Result ret;
        int fd;
        CameraFile file = null;
        string tmpname = "tmpfileXXXXXX";
        string? tmpfilename = null;

        fd = FileUtils.mkstemp (tmpname);
        if (fd == -1) {
            if (errno == Posix.EACCES) {
                context.error ("Permission denied");
            }
        } else {
            ret = CameraFile.create_from_fd (out file, fd);
            if (ret < Result.OK) {
                FileUtils.close (fd);
                FileUtils.unlink (tmpname);
                return ret;
            }
            tmpfilename = tmpname;
        }

        if (file != null) {
            ret = camera.get_file (folder, filename, type, file, context);
            if (ret < Result.OK) {
                if (tmpfilename != null) {
                    return ret;
                }
            }
        }

        //ret = save_camera_file ();

        return Result.OK;
    }

    private int save_captured_file (CameraFilePath path, bool download) {
        Result ret;
        string sep;
        CameraFilePath last;

        if ((string) path.folder == "/") {
            sep = "";
        } else {
            sep = "/";
        }

        stdout.printf ("New file is in location %s%s%s on the camera\n",
                       (string) path.folder, sep, (string) path.name);

        if (download) {
            ret = (Result) save_file ((string) path.folder,
                                      (string) path.name,
                                      CameraFileType.NORMAL);
        }

        return Result.OK;
    }

    public void capture (CameraCaptureType type, bool download)
                         throws GPhotoError {
        Result ret;
        int frame = 0;
        CameraFilePath path;
        CameraAbilities abilities;
        CameraEventType event;

        ret = camera.get_abilities (out abilities);
        if (ret != Result.OK) {
            throw new GPhotoError.LIBRARY (ret.to_full_string ());
        }

        do {
            frame++;
            ret = camera.capture (type, out path, context);
            if (ret != Result.OK) {
                throw new GPhotoError.LIBRARY (ret.to_full_string ());
            } else {
                /* Apparently some cameras return *UNKNOWN* as the filename if
                 * they are unable to get focus lock */
                if (interval != 0 && (string) path.name == "*UNKNOWN*") {
                    throw new GPhotoError.LIBRARY (
                        "Capture failed (auto-focus problem?): %s",
                        ret.as_string ());
                }

                ret = (Result) save_captured_file (path, download);
                if (ret != Result.OK) {
                    break;
                }
            }

            if (interval == 0) {
                break;
            }

            if (frame == frames) {
                break;
            }
        } while (frame != frames);
    }

    public static int main (string[] args) {
        var app = new App ();

        try {
            app.frames = 10;
            app.interval = 1;
            app.capture (CameraCaptureType.IMAGE, true);
        } catch (GPhotoError e) {
            error (e.message);
        }

        return 0;
    }
}
