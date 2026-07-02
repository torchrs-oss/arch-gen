use arboard::Clipboard;
use muda::{AboutMetadata, Menu, MenuEvent, PredefinedMenuItem, Submenu};
use tao::{
    dpi::LogicalSize,
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoopBuilder},
    window::WindowBuilder,
};
use wry::WebViewBuilder;

#[cfg(target_os = "linux")]
use tao::platform::unix::{EventLoopBuilderExtUnix, WindowExtUnix};
#[cfg(target_os = "linux")]
use wry::WebViewBuilderExtUnix;

#[cfg(target_os = "linux")]
const APP_ID: &str = "rs.torch.arch-gen";

enum UserEvent {
    MenuEvent(MenuEvent),
}

fn main() -> wry::Result<()> {
    #[cfg(target_os = "linux")]
    if std::env::var_os("WEBKIT_DISABLE_DMABUF_RENDERER").is_none() {
        // Work around WebKitGTK Wayland DMABUF protocol error (blank window).
        std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");
    }

    let categories_json = include_str!("../categories.json");
    let html_template = include_str!("ui.html");
    let html = html_template.replace("__CATEGORIES_JSON__", categories_json);

    let mut event_loop_builder = EventLoopBuilder::<UserEvent>::with_user_event();
    #[cfg(target_os = "linux")]
    event_loop_builder.with_app_id(APP_ID);
    let event_loop = event_loop_builder.build();

    let proxy = event_loop.create_proxy();
    MenuEvent::set_event_handler(Some(move |event| {
        let _ = proxy.send_event(UserEvent::MenuEvent(event));
    }));

    let window = WindowBuilder::new()
        .with_title("ARCH-GEN — Architecture Decision Randomizer")
        .with_inner_size(LogicalSize::new(1320.0, 860.0))
        .with_min_inner_size(LogicalSize::new(900.0, 600.0))
        .build(&event_loop)
        .unwrap();

    let menu = Menu::new();

    #[cfg(target_os = "macos")]
    {
        let app_menu = Submenu::new("Arch Gen", true);
        app_menu
            .append_items(&[
                &PredefinedMenuItem::about(
                    None,
                    Some(AboutMetadata {
                        name: Some("Arch Gen".into()),
                        version: Some(env!("CARGO_PKG_VERSION").into()),
                        ..Default::default()
                    }),
                ),
                &PredefinedMenuItem::separator(),
                &PredefinedMenuItem::services(None),
                &PredefinedMenuItem::separator(),
                &PredefinedMenuItem::hide(None),
                &PredefinedMenuItem::hide_others(None),
                &PredefinedMenuItem::show_all(None),
                &PredefinedMenuItem::separator(),
                &PredefinedMenuItem::quit(None),
            ])
            .unwrap();
        menu.append(&app_menu).unwrap();
    }

    let edit_menu = Submenu::new("Edit", true);
    edit_menu
        .append_items(&[
            &PredefinedMenuItem::undo(None),
            &PredefinedMenuItem::redo(None),
            &PredefinedMenuItem::separator(),
            &PredefinedMenuItem::cut(None),
            &PredefinedMenuItem::copy(None),
            &PredefinedMenuItem::paste(None),
            &PredefinedMenuItem::select_all(None),
        ])
        .unwrap();

    let window_menu = Submenu::new("Window", true);
    window_menu
        .append_items(&[
            &PredefinedMenuItem::minimize(None),
            &PredefinedMenuItem::fullscreen(None),
            &PredefinedMenuItem::separator(),
            &PredefinedMenuItem::close_window(None),
        ])
        .unwrap();

    menu.append_items(&[&edit_menu, &window_menu]).unwrap();

    #[cfg(target_os = "macos")]
    {
        menu.init_for_nsapp();
        window_menu.set_as_windows_menu_for_nsapp();
    }


    let builder = WebViewBuilder::new()
        .with_html(&html)
        .with_devtools(cfg!(debug_assertions))
        .with_ipc_handler(|req| {
            let body = req.body();
            if let Some(text) = body.strip_prefix("clipboard:") {
                if let Ok(mut cb) = Clipboard::new() {
                    let _ = cb.set_text(text);
                }
            }
        });

    #[cfg(not(target_os = "linux"))]
    let _webview = builder.build(&window)?;
    #[cfg(target_os = "linux")]
    let _webview = builder.build_gtk(window.default_vbox().unwrap())?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;
        match event {
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => {}
        }
    });
}
