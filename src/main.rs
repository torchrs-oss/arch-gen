use tao::{
    dpi::LogicalSize,
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::WindowBuilder,
};
use wry::WebViewBuilder;

fn main() -> wry::Result<()> {
    let categories_json = include_str!("../categories.json");
    let html_template = include_str!("ui.html");
    let html = html_template.replace("__CATEGORIES_JSON__", categories_json);

    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title("ARCH-GEN — Architecture Decision Randomizer")
        .with_inner_size(LogicalSize::new(1320.0, 860.0))
        .with_min_inner_size(LogicalSize::new(900.0, 600.0))
        .build(&event_loop)
        .unwrap();

    let _webview = WebViewBuilder::new()
        .with_html(&html)
        .with_devtools(cfg!(debug_assertions))
        .build(&window)?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;
        if let Event::WindowEvent {
            event: WindowEvent::CloseRequested,
            ..
        } = event
        {
            *control_flow = ControlFlow::Exit;
        }
    });
}
