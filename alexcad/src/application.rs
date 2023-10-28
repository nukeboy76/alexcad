
use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gio, glib};

use crate::config::VERSION;
use crate::AlexcadWindow;

mod imp {
    use super::*;

    #[derive(Debug, Default)]
    pub struct AlexcadApplication {}

    #[glib::object_subclass]
    impl ObjectSubclass for AlexcadApplication {
        const NAME: &'static str = "AlexcadApplication";
        type Type = super::AlexcadApplication;
        type ParentType = gtk::Application;
    }

    impl ObjectImpl for AlexcadApplication {
        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();
            obj.setup_gactions();
            obj.set_accels_for_action("app.quit", &["<primary>q"]);
        }
    }

    impl ApplicationImpl for AlexcadApplication {
        // We connect to the activate callback to create a window when the application
        // has been launched. Additionally, this callback notifies us when the user
        // tries to launch a "second instance" of the application. When they try
        // to do that, we'll just present any existing window.
        fn activate(&self) {
            let application = self.obj();
            // Get the current window or create one if necessary
            let window = if let Some(window) = application.active_window() {
                window
            } else {
                let window = AlexcadWindow::new(&*application);
                window.upcast()
            };

            // Ask the window manager/compositor to present the window
            window.present();
        }
    }

    impl GtkApplicationImpl for AlexcadApplication {}
    }

glib::wrapper! {
    pub struct AlexcadApplication(ObjectSubclass<imp::AlexcadApplication>)
        @extends gio::Application, gtk::Application, 
        @implements gio::ActionGroup, gio::ActionMap;
}

impl AlexcadApplication {
    pub fn new(application_id: &str, flags: &gio::ApplicationFlags) -> Self {
        glib::Object::builder()
            .property("application-id", application_id)
            .property("flags", flags)
            .build()
    }

    fn setup_gactions(&self) {
        let quit_action = gio::ActionEntry::builder("quit")
            .activate(move |app: &Self, _, _| app.quit())
            .build();
        let about_action = gio::ActionEntry::builder("about")
            .activate(move |app: &Self, _, _| app.show_about())
            .build();
        self.add_action_entries([quit_action, about_action]);
    }

    fn show_about(&self) {
        let window = self.active_window().unwrap();
        let about = gtk::AboutDialog::builder()
            .transient_for(&window)
            .modal(true)
            .program_name("alexcad")
            .logo_icon_name("org.gnome.Example")
            .version(VERSION)
            .authors(vec!["Unknown"])
            .copyright("© 2023 Unknown")
            .build();

        about.present();
    }
}
