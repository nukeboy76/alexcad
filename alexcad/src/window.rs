
use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gio, glib};

mod imp {
    use super::*;

    #[derive(Debug, Default, gtk::CompositeTemplate)]
    #[template(resource = "/org/gnome/Example/window.ui")]
    pub struct AlexcadWindow {
        // Template widgets
        #[template_child]
        pub header_bar: TemplateChild<gtk::HeaderBar>,
        #[template_child]
        pub label: TemplateChild<gtk::Label>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for AlexcadWindow {
        const NAME: &'static str = "AlexcadWindow";
        type Type = super::AlexcadWindow;
        type ParentType = gtk::ApplicationWindow;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    impl ObjectImpl for AlexcadWindow {}
    impl WidgetImpl for AlexcadWindow {}
    impl WindowImpl for AlexcadWindow {}
    impl ApplicationWindowImpl for AlexcadWindow {}
}

glib::wrapper! {
    pub struct AlexcadWindow(ObjectSubclass<imp::AlexcadWindow>)
        @extends gtk::Widget, gtk::Window, gtk::ApplicationWindow,        @implements gio::ActionGroup, gio::ActionMap;
}

impl AlexcadWindow {
    pub fn new<P: glib::IsA<gtk::Application>>(application: &P) -> Self {
        glib::Object::builder()
            .property("application", application)
            .build()
    }
}
