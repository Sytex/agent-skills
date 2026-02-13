use std::net::TcpListener;
use std::process::{Child, Command};
use std::sync::Mutex;
use std::time::{Duration, Instant};

use tauri::Manager;
use tauri_plugin_updater::UpdaterExt;

fn find_available_port() -> u16 {
    let listener = TcpListener::bind("127.0.0.1:0").expect("Failed to bind to port 0");
    let port = listener.local_addr().unwrap().port();
    drop(listener);
    port
}

fn wait_for_server(port: u16, timeout: Duration) -> bool {
    let start = Instant::now();
    while start.elapsed() < timeout {
        if TcpListener::bind(("127.0.0.1", port)).is_err() {
            // Port is in use — server is up
            return true;
        }
        std::thread::sleep(Duration::from_millis(100));
    }
    false
}

struct ServerProcess(Mutex<Option<Child>>);

impl Drop for ServerProcess {
    fn drop(&mut self) {
        if let Some(mut child) = self.0.lock().unwrap().take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

pub fn run() {
    let port = find_available_port();

    tauri::Builder::default()
        .plugin(tauri_plugin_updater::Builder::new().build())
        .setup(move |app| {
            let resource_path = app.path().resource_dir()?;
            let server_bin = resource_path.join("agent-skills-server");
            let skills_dir = resource_path.join("skills");

            let child = Command::new(&server_bin)
                .arg("--no-browser")
                .arg(port.to_string())
                .env("SKILLS_DIR", &skills_dir)
                .env("BUNDLED_MODE", "1")
                .spawn()
                .expect("Failed to start agent-skills-server");

            app.manage(ServerProcess(Mutex::new(Some(child))));

            let server_ready = wait_for_server(port, Duration::from_secs(10));
            if !server_ready {
                eprintln!("Warning: web.py did not start within 10 seconds");
            }

            let url = format!("http://localhost:{}", port);
            let main_window = app.get_webview_window("main").unwrap();
            main_window.navigate(url.parse().unwrap())?;

            // Check for updates in background
            let app_handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                let updater = app_handle.updater().expect("Failed to get updater");
                match updater.check().await {
                    Ok(Some(update)) => {
                        eprintln!(
                            "Update available: {} -> {}",
                            update.current_version,
                            update.version
                        );
                        let result = update.download_and_install(|_, _| {}, || {}).await;
                        if let Err(e) = result {
                            eprintln!("Failed to install update: {}", e);
                        }
                    }
                    Ok(None) => {}
                    Err(e) => {
                        eprintln!("Update check failed: {}", e);
                    }
                }
            });

            Ok(())
        })
        .on_window_event(|window, event| {
            if let tauri::WindowEvent::Destroyed = event {
                if let Some(state) = window.try_state::<ServerProcess>() {
                    if let Some(mut child) = state.0.lock().unwrap().take() {
                        let _ = child.kill();
                        let _ = child.wait();
                    }
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("Error running Agent Skills");
}
