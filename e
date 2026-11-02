<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Audio Receiver & On-Demand Streamer</title>
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {
                    colors: {
                        brand: {
                            50: '#f0fdfa',
                            100: '#ccfbf1',
                            400: '#2dd4bf',
                            500: '#14b8a6',
                            600: '#0d9488',
                            900: '#134e4a',
                            cyan: '#06b6d4',
                            neon: '#00f0ff',
                            purple: '#a855f7'
                        },
                        darkbg: '#0a0d14',
                        cardbg: '#121824',
                        borderbg: '#1e293b'
                    },
                    fontFamily: {
                        sans: ['Inter', 'sans-serif'],
                        mono: ['JetBrains Mono', 'Fira Code', 'monospace']
                    }
                }
            }
        }
    </script>
    <!-- FontAwesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #0a0d14;
            color: #f1f5f9;
        }
        .glow-neon {
            box-shadow: 0 0 20px rgba(0, 240, 255, 0.25);
        }
        .glow-purple {
            box-shadow: 0 0 20px rgba(168, 85, 247, 0.25);
        }
        /* Custom scrollbar */
        ::-webkit-scrollbar {
            width: 8px;
            height: 8px;
        }
        ::-webkit-scrollbar-track {
            background: #0a0d14;
        }
        ::-webkit-scrollbar-thumb {
            background: #1e293b;
            border-radius: 4px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: #334155;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col bg-darkbg text-slate-100 overflow-x-hidden selection:bg-cyan-500 selection:text-black">

    <!-- Toast Notification -->
    <div id="toast" class="fixed bottom-5 right-5 z-50 transform translate-y-20 opacity-0 transition-all duration-300 pointer-events-none flex items-center space-x-3 bg-slate-800 border border-cyan-500/50 text-cyan-300 px-4 py-3 rounded-xl shadow-2xl backdrop-blur-md">
        <i class="fa-solid fa-circle-check text-cyan-400"></i>
        <span id="toast-message" class="text-sm font-medium">Notification message</span>
    </div>

    <!-- Header -->
    <header class="border-b border-slate-800/80 bg-slate-950/60 backdrop-blur-md sticky top-0 z-40">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
            <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-cyan-500 to-purple-600 flex items-center justify-center shadow-lg shadow-cyan-500/20">
                    <i class="fa-solid fa-wave-square text-slate-950 text-lg font-bold"></i>
                </div>
                <div>
                    <h1 class="text-lg font-bold tracking-tight text-white flex items-center gap-2">
                        PulseLink <span class="text-xs font-semibold px-2 py-0.5 rounded-full bg-cyan-950 text-cyan-400 border border-cyan-800/60">Audio WebRX</span>
                    </h1>
                    <p class="text-xs text-slate-400">Linux On-Demand Audio Receiver</p>
                </div>
            </div>

            <!-- Global Status Indicator -->
            <div class="flex items-center space-x-3">
                <div id="status-badge" class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/30 transition-all duration-300">
                    <span class="w-2 h-2 rounded-full bg-amber-400 animate-pulse mr-2" id="status-dot"></span>
                    <span id="status-text">Disconnected</span>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Container -->
    <main class="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 flex flex-col gap-8">
        
        <!-- Navigation Tabs -->
        <div class="flex border-b border-slate-800/80 space-x-2 sm:space-x-8">
            <button id="tab-btn-player" onclick="switchTab('player')" class="pb-3 px-1 border-b-2 border-cyan-400 font-medium text-sm text-cyan-400 flex items-center space-x-2 transition-colors">
                <i class="fa-solid fa-radio"></i>
                <span>Receiver Dashboard</span>
            </button>
            <button id="tab-btn-guide" onclick="switchTab('guide')" class="pb-3 px-1 border-b-2 border-transparent font-medium text-sm text-slate-400 hover:text-slate-200 flex items-center space-x-2 transition-colors">
                <i class="fa-solid fa-terminal"></i>
                <span>Streaming Setup Guide & Port Fix</span>
            </button>
        </div>

        <!-- TAB 1: PLAYER DASHBOARD -->
        <div id="tab-player" class="grid grid-cols-1 lg:grid-cols-12 gap-8">
            
            <!-- Left Side: Main Visualizer & Audio Controls (8 Cols) -->
            <div class="lg:col-span-8 flex flex-col gap-6">
                
                <!-- Main Audio Card -->
                <div class="bg-cardbg border border-slate-800 rounded-2xl p-6 shadow-xl relative overflow-hidden flex flex-col justify-between">
                    <!-- Background ambient glow -->
                    <div class="absolute -top-24 -right-24 w-60 h-60 bg-cyan-500/10 rounded-full blur-3xl pointer-events-none"></div>
                    <div class="absolute -bottom-24 -left-24 w-60 h-60 bg-purple-500/10 rounded-full blur-3xl pointer-events-none"></div>

                    <!-- Canvas Visualizer Header -->
                    <div class="flex items-center justify-between mb-4 z-10">
                        <div class="flex items-center space-x-3">
                            <span class="text-xs font-mono uppercase tracking-wider text-slate-400">Stream Visualizer</span>
                            <span id="bitrate-tag" class="text-[10px] font-mono bg-cyan-950 text-cyan-300 border border-cyan-800/60 px-2 py-0.5 rounded">ASYNC SAFE ENGINE</span>
                        </div>
                        
                        <!-- Visualizer Mode Selector -->
                        <div class="flex bg-slate-900/80 p-1 rounded-lg border border-slate-800 text-xs">
                            <button id="vis-bars-btn" onclick="setVisualizerMode('bars')" class="px-2.5 py-1 rounded-md text-cyan-400 bg-slate-800 font-medium transition-all">Bars</button>
                            <button id="vis-wave-btn" onclick="setVisualizerMode('wave')" class="px-2.5 py-1 rounded-md text-slate-400 hover:text-slate-200 font-medium transition-all">Wave</button>
                            <button id="vis-circle-btn" onclick="setVisualizerMode('circle')" class="px-2.5 py-1 rounded-md text-slate-400 hover:text-slate-200 font-medium transition-all">Circle</button>
                        </div>
                    </div>

                    <!-- Canvas Element -->
                    <div class="relative w-full h-64 bg-slate-950/80 rounded-xl border border-slate-800/80 overflow-hidden flex items-center justify-center mb-6 shadow-inner">
                        <canvas id="visualizer-canvas" class="w-full h-full block"></canvas>
                        
                        <!-- Overlay when stopped -->
                        <div id="canvas-overlay" class="absolute inset-0 flex flex-col items-center justify-center bg-slate-950/70 backdrop-blur-xs transition-opacity duration-300">
                            <div class="w-16 h-16 rounded-full bg-slate-900/90 border border-cyan-500/30 flex items-center justify-center mb-3 shadow-lg">
                                <i class="fa-solid fa-play text-cyan-400 text-2xl ml-1" id="overlay-icon"></i>
                            </div>
                            <p class="text-sm font-medium text-slate-300" id="overlay-msg">Click 'Start Receiver' to initiate stream playback</p>
                        </div>
                    </div>

                    <!-- Stream Stats Bar -->
                    <div class="grid grid-cols-3 gap-4 mb-6 bg-slate-950/40 border border-slate-800/60 p-3 rounded-xl text-center">
                        <div>
                            <p class="text-[10px] uppercase font-mono text-slate-500">Audio Latency</p>
                            <p class="text-sm font-semibold font-mono text-slate-200" id="stat-latency">-- ms</p>
                        </div>
                        <div>
                            <p class="text-[10px] uppercase font-mono text-slate-500">Peak Signal</p>
                            <p class="text-sm font-semibold font-mono text-cyan-400" id="stat-peak">- INF dB</p>
                        </div>
                        <div>
                            <p class="text-[10px] uppercase font-mono text-slate-500">Format</p>
                            <p class="text-sm font-semibold font-mono text-slate-200" id="stat-format">44.1kHz PCM/Stream</p>
                        </div>
                    </div>

                    <!-- Playback Controls -->
                    <div class="flex flex-col sm:flex-row items-center justify-between gap-4 z-10 pt-2 border-t border-slate-800/60">
                        
                        <!-- Main Toggle Action -->
                        <div class="flex items-center space-x-3 w-full sm:w-auto justify-center">
                            <button id="btn-toggle-play" onclick="toggleStream()" class="w-full sm:w-auto px-6 py-3 rounded-xl font-semibold bg-gradient-to-r from-cyan-500 to-cyan-600 hover:from-cyan-400 hover:to-cyan-500 text-slate-950 flex items-center justify-center space-x-2 shadow-lg shadow-cyan-500/20 active:scale-95 transition-all">
                                <i class="fa-solid fa-play" id="btn-play-icon"></i>
                                <span id="btn-play-text">Start Receiver</span>
                            </button>

                            <button id="btn-mute" onclick="toggleMute()" class="p-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 transition-colors">
                                <i class="fa-solid fa-volume-high text-lg" id="btn-mute-icon"></i>
                            </button>
                        </div>

                        <!-- Volume Slider -->
                        <div class="flex items-center space-x-3 w-full sm:w-64 bg-slate-900/60 p-2.5 rounded-xl border border-slate-800/80">
                            <i class="fa-solid fa-volume-low text-slate-400 text-xs"></i>
                            <input type="range" id="volume-slider" min="0" max="1" step="0.01" value="0.8" oninput="updateVolume(this.value)" class="w-full h-1.5 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-cyan-400">
                            <span id="volume-val" class="text-xs font-mono font-medium text-slate-300 w-8 text-right">80%</span>
                        </div>
                    </div>

                </div>

                <!-- Info banner -->
                <div class="bg-cyan-950/20 border border-cyan-800/30 rounded-xl p-4 flex items-start space-x-3">
                    <i class="fa-solid fa-circle-info text-cyan-400 text-lg mt-0.5"></i>
                    <div class="text-xs text-slate-300 leading-relaxed">
                        <strong class="text-cyan-300">Fixed Interruption & Port Issues:</strong> Port 8080 is commonly used by development tools. We defaulted to <strong>8085</strong>. Audio requests now use explicit promise handling to prevent browser `.play()` interruption errors.
                    </div>
                </div>

            </div>

            <!-- Right Side: Stream Settings & Connection presets (4 Cols) -->
            <div class="lg:col-span-4 flex flex-col gap-6">
                
                <!-- Stream Configuration Panel -->
                <div class="bg-cardbg border border-slate-800 rounded-2xl p-6 shadow-xl">
                    <h2 class="text-base font-semibold text-white mb-4 flex items-center space-x-2">
                        <i class="fa-solid fa-sliders text-cyan-400"></i>
                        <span>Stream Target Config</span>
                    </h2>

                    <form id="stream-config-form" onsubmit="applyStreamUrl(event)" class="space-y-4">
                        <div>
                            <label class="block text-xs font-medium text-slate-400 mb-1.5">Stream Mode / Source Type</label>
                            <select id="stream-type" onchange="handleTypeChange()" class="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-sm text-slate-200 focus:outline-none focus:border-cyan-500 font-mono">
                                <option value="http-audio">HTTP Live Stream (MP3/OGG/WAV)</option>
                                <option value="icecast">Icecast / Shoutcast Server URL</option>
                                <option value="demo">Synthetic Test Tone (No Linux Server Required)</option>
                            </select>
                        </div>

                        <div>
                            <label class="block text-xs font-medium text-slate-400 mb-1.5">Stream URL Endpoint</label>
                            <div class="relative">
                                <input type="text" id="stream-url-input" placeholder="http://192.168.1.100:8085/stream" class="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-xs text-slate-200 focus:outline-none focus:border-cyan-500 font-mono pr-8">
                                <button type="button" onclick="clearStreamUrl()" class="absolute right-2.5 top-2.5 text-slate-500 hover:text-slate-300 text-xs">
                                    <i class="fa-solid fa-xmark"></i>
                                </button>
                            </div>
                            <p class="text-[11px] text-slate-500 mt-1">Replace with your Linux sender IP and port.</p>
                        </div>

                        <!-- Quick Port Selector -->
                        <div>
                            <label class="block text-xs font-medium text-slate-400 mb-1.5">Quick Port Select</label>
                            <div class="grid grid-cols-4 gap-1.5">
                                <button type="button" onclick="changePort(8085)" class="py-1 px-2 rounded bg-slate-900 hover:bg-slate-800 text-xs text-cyan-400 font-mono border border-slate-800">8085</button>
                                <button type="button" onclick="changePort(9000)" class="py-1 px-2 rounded bg-slate-900 hover:bg-slate-800 text-xs text-cyan-400 font-mono border border-slate-800">9000</button>
                                <button type="button" onclick="changePort(8000)" class="py-1 px-2 rounded bg-slate-900 hover:bg-slate-800 text-xs text-cyan-400 font-mono border border-slate-800">8000</button>
                                <button type="button" onclick="changePort(8080)" class="py-1 px-2 rounded bg-slate-900 hover:bg-slate-800 text-xs text-slate-400 font-mono border border-slate-800">8080</button>
                            </div>
                        </div>

                        <div class="pt-2">
                            <button type="submit" class="w-full py-2.5 px-4 bg-slate-800 hover:bg-slate-700 text-cyan-300 border border-cyan-500/30 rounded-xl font-medium text-xs flex items-center justify-center space-x-2 transition-all">
                                <i class="fa-solid fa-plug"></i>
                                <span>Save & Reconnect</span>
                            </button>
                        </div>
                    </form>

                    <div class="mt-6 pt-4 border-t border-slate-800">
                        <span class="text-xs font-medium text-slate-400 block mb-2">Preset Streaming Endpoints</span>
                        <div class="grid grid-cols-2 gap-2">
                            <button onclick="setPreset('http', 8085, '/stream')" class="p-2 rounded-lg bg-slate-900 border border-slate-800 hover:border-slate-700 text-left transition-colors">
                                <span class="text-xs font-bold text-slate-200 block">FFmpeg Port 8085</span>
                                <span class="text-[10px] font-mono text-slate-500">HTTP /stream</span>
                            </button>
                            <button onclick="setPreset('http', 9000, '/audio.mp3')" class="p-2 rounded-lg bg-slate-900 border border-slate-800 hover:border-slate-700 text-left transition-colors">
                                <span class="text-xs font-bold text-slate-200 block">Alt Port 9000</span>
                                <span class="text-[10px] font-mono text-slate-500">HTTP /audio.mp3</span>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Active Connection Info Box -->
                <div class="bg-cardbg border border-slate-800 rounded-2xl p-5 shadow-xl">
                    <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-400 mb-3">Audio Diagnostics Log</h3>
                    <div id="log-container" class="bg-slate-950 p-3 rounded-xl border border-slate-900 font-mono text-[11px] h-36 overflow-y-auto space-y-1 text-slate-400">
                        <div><span class="text-slate-600">[00:00:00]</span> System initialized with play Promise safety lock.</div>
                    </div>
                </div>

            </div>

        </div>

        <!-- TAB 2: STREAM SETUP GUIDE -->
        <div id="tab-guide" class="hidden flex-col gap-6">
            <div class="bg-cardbg border border-slate-800 rounded-2xl p-6 sm:p-8 shadow-xl max-w-5xl mx-auto w-full">
                <div class="mb-6">
                    <h2 class="text-2xl font-bold text-white mb-2 flex items-center gap-3">
                        <i class="fa-brands fa-linux text-cyan-400"></i>
                        Linux Sender Setup & Port Troubleshooting
                    </h2>
                    <p class="text-sm text-slate-400">Run these commands on your Linux sender machine. We use port <strong>8085</strong> by default to avoid port 8080 collisions.</p>
                </div>

                <!-- Troubleshooting Section for Port 8080 conflict -->
                <div class="mb-8 p-5 bg-amber-950/20 border border-amber-500/30 rounded-xl space-y-3">
                    <div class="flex items-center justify-between">
                        <h3 class="text-sm font-bold text-amber-400 flex items-center gap-2">
                            <i class="fa-solid fa-triangle-exclamation"></i>
                            Port 8080 Already In Use? Free or Troubleshoot Ports
                        </h3>
                        <button onclick="copyCode('code-kill-port')" class="text-xs bg-amber-900/40 hover:bg-amber-800/60 text-amber-300 px-3 py-1 rounded border border-amber-500/30">Copy Kill Cmd</button>
                    </div>
                    <p class="text-xs text-slate-300">If port 8080 (or 8085) is locked by another process (like web servers or dev containers), inspect or kill the process blocking the port on your Linux host:</p>
                    <pre id="code-kill-port" class="bg-slate-950 p-3 rounded-lg text-xs font-mono text-amber-300 border border-slate-800"># Check what is using port 8080 or 8085
sudo lsof -i :8080  # or sudo ss -tulpn | grep 8080

# Kill process running on port 8080 instantly
sudo fuser -k 8080/tcp

# Alternatively, just use default Port 8085 with FFmpeg below!</pre>
                </div>

                <!-- Guide Method Selector -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                    <button onclick="showGuideMethod('ffmpeg')" id="guide-tab-ffmpeg" class="p-4 rounded-xl border bg-cyan-950/30 border-cyan-500/50 text-cyan-300 text-left transition-all">
                        <div class="flex items-center justify-between mb-2">
                            <span class="font-bold text-sm">Method 1: FFmpeg (Port 8085)</span>
                            <span class="text-[10px] bg-cyan-500/20 text-cyan-300 px-2 py-0.5 rounded font-mono">Recommended</span>
                        </div>
                        <p class="text-xs text-slate-400">Streams system sound over HTTP port 8085 using PipeWire/PulseAudio.</p>
                    </button>

                    <button onclick="showGuideMethod('vlc')" id="guide-tab-vlc" class="p-4 rounded-xl border bg-slate-900 border-slate-800 text-slate-400 text-left hover:border-slate-700 transition-all">
                        <div class="flex items-center justify-between mb-2">
                            <span class="font-bold text-sm text-slate-200">Method 2: cvlc Stream</span>
                            <span class="text-[10px] bg-purple-500/20 text-purple-300 px-2 py-0.5 rounded font-mono">Port 8085</span>
                        </div>
                        <p class="text-xs text-slate-400">Uses headless VLC to stream audio output over HTTP port 8085.</p>
                    </button>

                    <button onclick="showGuideMethod('icecast')" id="guide-tab-icecast" class="p-4 rounded-xl border bg-slate-900 border-slate-800 text-slate-400 text-left hover:border-slate-700 transition-all">
                        <div class="flex items-center justify-between mb-2">
                            <span class="font-bold text-sm text-slate-200">Method 3: Icecast</span>
                            <span class="text-[10px] bg-emerald-500/20 text-emerald-300 px-2 py-0.5 rounded font-mono">Port 8000</span>
                        </div>
                        <p class="text-xs text-slate-400">Sends PulseAudio audio feed to an Icecast broadcast server.</p>
                    </button>
                </div>

                <!-- Method Content Panels -->
                
                <!-- FFmpeg Guide -->
                <div id="method-ffmpeg" class="space-y-6">
                    <div class="bg-slate-950 p-5 rounded-xl border border-slate-800 space-y-3">
                        <div class="flex items-center justify-between">
                            <h3 class="text-sm font-semibold text-cyan-300">1. Capture System Monitor Audio (Port 8085)</h3>
                            <button onclick="copyCode('code-ffmpeg-1')" class="text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 px-3 py-1.5 rounded-lg border border-slate-700 transition-colors flex items-center space-x-1.5">
                                <i class="fa-regular fa-copy"></i>
                                <span>Copy</span>
                            </button>
                        </div>
                        <p class="text-xs text-slate-400">Run this command on your Linux terminal to start an instant MP3 HTTP audio server on port 8085:</p>
                        <pre id="code-ffmpeg-1" class="bg-slate-900 p-3 rounded-lg text-xs font-mono text-emerald-400 overflow-x-auto border border-slate-800/80">ffmpeg -f pulse -i default -f mp3 -content_type audio/mpeg -listen 1 http://0.0.0.0:8085/stream</pre>
                    </div>

                    <div class="bg-slate-950 p-5 rounded-xl border border-slate-800 space-y-3">
                        <div class="flex items-center justify-between">
                            <h3 class="text-sm font-semibold text-cyan-300">2. Low Latency OGG Stream (Port 9000 Alternative)</h3>
                            <button onclick="copyCode('code-ffmpeg-2')" class="text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 px-3 py-1.5 rounded-lg border border-slate-700 transition-colors flex items-center space-x-1.5">
                                <i class="fa-regular fa-copy"></i>
                                <span>Copy</span>
                            </button>
                        </div>
                        <p class="text-xs text-slate-400">If port 8085 is busy, run on port 9000 with low-latency OGG encoding:</p>
                        <pre id="code-ffmpeg-2" class="bg-slate-900 p-3 rounded-lg text-xs font-mono text-emerald-400 overflow-x-auto border border-slate-800/80">ffmpeg -f pulse -i default -acodec libvorbis -f ogg -content_type audio/ogg -listen 1 http://0.0.0.0:9000/stream</pre>
                    </div>
                </div>

                <!-- VLC Guide -->
                <div id="method-vlc" class="hidden space-y-6">
                    <div class="bg-slate-950 p-5 rounded-xl border border-slate-800 space-y-3">
                        <div class="flex items-center justify-between">
                            <h3 class="text-sm font-semibold text-purple-300">1. Stream Audio via VLC Command Line (Port 8085)</h3>
                            <button onclick="copyCode('code-vlc-1')" class="text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 px-3 py-1.5 rounded-lg border border-slate-700 transition-colors flex items-center space-x-1.5">
                                <i class="fa-regular fa-copy"></i>
                                <span>Copy</span>
                            </button>
                        </div>
                        <p class="text-xs text-slate-400">Streams default PulseAudio sink via VLC command line player on port 8085:</p>
                        <pre id="code-vlc-1" class="bg-slate-900 p-3 rounded-lg text-xs font-mono text-purple-300 overflow-x-auto border border-slate-800/80">cvlc pulse://default --sout '#transcode{vcodec=none,acodec=mp3,ab=128,channels=2,samplerate=44100}:http{mux=mp3,dst=:8085/stream}'</pre>
                    </div>
                </div>

                <!-- Icecast Guide -->
                <div id="method-icecast" class="hidden space-y-6">
                    <div class="bg-slate-950 p-5 rounded-xl border border-slate-800 space-y-3">
                        <div class="flex items-center justify-between">
                            <h3 class="text-sm font-semibold text-emerald-300">1. Stream to an Existing Icecast Server</h3>
                            <button onclick="copyCode('code-icecast-1')" class="text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 px-3 py-1.5 rounded-lg border border-slate-700 transition-colors flex items-center space-x-1.5">
                                <i class="fa-regular fa-copy"></i>
                                <span>Copy</span>
                            </button>
                        </div>
                        <p class="text-xs text-slate-400">Sends system audio feed to a running local/remote Icecast instance:</p>
                        <pre id="code-icecast-1" class="bg-slate-900 p-3 rounded-lg text-xs font-mono text-emerald-300 overflow-x-auto border border-slate-800/80">ffmpeg -f pulse -i default -ac 2 -codec:a libmp3lame -b:a 128k -content_type audio/mpeg -f mp3 icecast://source:hackme@localhost:8000/stream.mp3</pre>
                    </div>
                </div>

            </div>
        </div>

    </main>

    <!-- Audio Element Hidden -->
    <audio id="audio-element" crossorigin="anonymous" class="hidden"></audio>

    <!-- Footer -->
    <footer class="border-t border-slate-800/80 bg-slate-950/60 py-4 mt-auto">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-2">
            <p>PulseLink Receiver &bull; PipeWire & PulseAudio Web Streamer</p>
            <p class="font-mono">Web Audio API & Canvas Visualizer Engine</p>
        </div>
    </footer>

    <!-- JavaScript Logic -->
    <script>
        // State variables
        let audioCtx = null;
        let analyser = null;
        let sourceNode = null;
        let synthOsc = null;
        let isPlaying = false;
        let isMuted = false;
        let visualizerMode = 'bars';
        let animFrameId = null;
        let playPromise = null; // Safety Promise tracker to prevent play/pause interrupt errors

        const audioElement = document.getElementById('audio-element');
        const canvas = document.getElementById('visualizer-canvas');
        const canvasCtx = canvas.getContext('2d');

        // Initial setup on window load
        window.onload = function() {
            resizeCanvas();
            window.addEventListener('resize', resizeCanvas);
            
            // Set default URL based on window location using port 8085
            const defaultIp = window.location.hostname || '192.168.1.100';
            document.getElementById('stream-url-input').value = `http://${defaultIp}:8085/stream`;
            
            logMessage("System initialized. Play promise safety locks enabled.");
        };

        function resizeCanvas() {
            if (canvas && canvas.parentElement) {
                canvas.width = canvas.parentElement.clientWidth;
                canvas.height = canvas.parentElement.clientHeight;
            }
        }

        // Navigation Tabs
        function switchTab(tab) {
            const playerTab = document.getElementById('tab-player');
            const guideTab = document.getElementById('tab-guide');
            const btnPlayer = document.getElementById('tab-btn-player');
            const btnGuide = document.getElementById('tab-btn-guide');

            if (tab === 'player') {
                playerTab.classList.remove('hidden');
                playerTab.classList.add('grid');
                guideTab.classList.add('hidden');
                guideTab.classList.remove('flex');

                btnPlayer.className = "pb-3 px-1 border-b-2 border-cyan-400 font-medium text-sm text-cyan-400 flex items-center space-x-2 transition-colors";
                btnGuide.className = "pb-3 px-1 border-b-2 border-transparent font-medium text-sm text-slate-400 hover:text-slate-200 flex items-center space-x-2 transition-colors";
                resizeCanvas();
            } else {
                playerTab.classList.add('hidden');
                playerTab.classList.remove('grid');
                guideTab.classList.remove('hidden');
                guideTab.classList.add('flex');

                btnGuide.className = "pb-3 px-1 border-b-2 border-cyan-400 font-medium text-sm text-cyan-400 flex items-center space-x-2 transition-colors";
                btnPlayer.className = "pb-3 px-1 border-b-2 border-transparent font-medium text-sm text-slate-400 hover:text-slate-200 flex items-center space-x-2 transition-colors";
            }
        }

        function showGuideMethod(method) {
            ['ffmpeg', 'vlc', 'icecast'].forEach(m => {
                const el = document.getElementById(`method-${m}`);
                const btn = document.getElementById(`guide-tab-${m}`);
                if (m === method) {
                    el.classList.remove('hidden');
                    btn.className = "p-4 rounded-xl border bg-cyan-950/30 border-cyan-500/50 text-cyan-300 text-left transition-all";
                } else {
                    el.classList.add('hidden');
                    btn.className = "p-4 rounded-xl border bg-slate-900 border-slate-800 text-slate-400 text-left hover:border-slate-700 transition-all";
                }
            });
        }

        // Web Audio Context & Playback Engine
        function initAudioContext() {
            if (!audioCtx) {
                const AudioContext = window.AudioContext || window.webkitAudioContext;
                audioCtx = new AudioContext();
            }

            if (!analyser) {
                analyser = audioCtx.createAnalyser();
                analyser.fftSize = 256;
            }
        }

        async function toggleStream() {
            if (isPlaying) {
                await stopStream();
            } else {
                await startStream();
            }
        }

        async function startStream() {
            initAudioContext();
            
            if (audioCtx.state === 'suspended') {
                await audioCtx.resume();
            }

            const streamType = document.getElementById('stream-type').value;
            const url = document.getElementById('stream-url-input').value;

            updateStatus('connecting', 'Connecting...');
            logMessage(`Attempting connection to: ${url}`);

            if (streamType === 'demo') {
                startDemoTone();
            } else {
                await startAudioElementStream(url);
            }
        }

        async function startAudioElementStream(url) {
            // Clean synth if active
            if (synthOsc) {
                try { synthOsc.stop(); } catch(e){}
                synthOsc = null;
            }

            audioElement.src = url;
            audioElement.volume = parseFloat(document.getElementById('volume-slider').value);

            // Connect node to Web Audio API analyzer if not done
            if (!sourceNode) {
                try {
                    sourceNode = audioCtx.createMediaElementSource(audioElement);
                    sourceNode.connect(analyser);
                    analyser.connect(audioCtx.destination);
                } catch (e) {
                    console.log("Media element source connected or CORS active", e);
                }
            }

            try {
                // Store play promise to prevent play interruption error
                playPromise = audioElement.play();
                await playPromise;
                
                isPlaying = true;
                updateStatus('connected', 'Live Stream Active');
                updateUIState(true);
                logMessage("Connected successfully to audio stream.");
                startVisualizer();
            } catch (err) {
                // Interruption error handling
                if (err.name === 'AbortError') {
                    logMessage("Play request clean abort handled.");
                } else if (err.name === 'NotAllowedError') {
                    logMessage("Autoplay policy blocked playback. User interaction required.");
                    showToast("Click 'Start Receiver' to allow browser audio playback.");
                } else {
                    logMessage(`Stream error: ${err.message || 'Connection refused or port blocked'}`);
                    showToast("Could not connect to URL. Check if sender terminal is active.");
                }
                updateStatus('disconnected', 'Stream Unavailable');
                updateUIState(false);
                isPlaying = false;
            } finally {
                playPromise = null;
            }

            audioElement.onerror = () => {
                updateStatus('disconnected', 'Stream Error');
                logMessage("Stream connection dropped or port blocked.");
                stopStream();
            };
        }

        // Synthetic Demo Sound Synthesizer
        function startDemoTone() {
            if (sourceNode) {
                try { audioElement.pause(); } catch(e){}
            }

            synthOsc = audioCtx.createOscillator();
            const gainNode = audioCtx.createGain();
            
            synthOsc.type = 'sine';
            synthOsc.frequency.setValueAtTime(220, audioCtx.currentTime);

            let lfo = audioCtx.createOscillator();
            lfo.frequency.value = 0.5;
            let lfoGain = audioCtx.createGain();
            lfoGain.gain.value = 100;
            lfo.connect(synthOsc.frequency);
            lfo.start();

            gainNode.gain.value = parseFloat(document.getElementById('volume-slider').value) * 0.3;

            synthOsc.connect(gainNode);
            gainNode.connect(analyser);
            analyser.connect(audioCtx.destination);

            synthOsc.start();
            isPlaying = true;

            updateStatus('connected', 'Demo Synthesizer Active');
            updateUIState(true);
            logMessage("Synthetic tone generator active for visualizer testing.");
            startVisualizer();
        }

        async function stopStream() {
            isPlaying = false;

            if (audioElement) {
                // Safely wait for pending play request to resolve before calling pause
                if (playPromise !== null) {
                    try {
                        await playPromise;
                    } catch (e) {
                        // Suppress unhandled promise rejection error on manual stop
                    }
                }
                audioElement.pause();
                audioElement.removeAttribute('src');
                audioElement.load();
            }

            if (synthOsc) {
                try { synthOsc.stop(); } catch(e){}
                synthOsc = null;
            }

            if (animFrameId) {
                cancelAnimationFrame(animFrameId);
            }

            updateStatus('disconnected', 'Disconnected');
            updateUIState(false);
            logMessage("Receiver safely stopped.");

            // Clear canvas
            canvasCtx.clearRect(0, 0, canvas.width, canvas.height);
        }

        function updateUIState(active) {
            const btnIcon = document.getElementById('btn-play-icon');
            const btnText = document.getElementById('btn-play-text');
            const overlay = document.getElementById('canvas-overlay');
            const overlayMsg = document.getElementById('overlay-msg');
            const overlayIcon = document.getElementById('overlay-icon');

            if (active) {
                btnIcon.className = "fa-solid fa-square";
                btnText.innerText = "Stop Receiver";
                overlay.classList.add('opacity-0', 'pointer-events-none');
            } else {
                btnIcon.className = "fa-solid fa-play";
                btnText.innerText = "Start Receiver";
                overlay.classList.remove('opacity-0', 'pointer-events-none');
                overlayMsg.innerText = "Click 'Start Receiver' to initiate stream playback";
                overlayIcon.className = "fa-solid fa-play text-cyan-400 text-2xl ml-1";
            }
        }

        function updateStatus(state, text) {
            const badge = document.getElementById('status-badge');
            const dot = document.getElementById('status-dot');
            const statusText = document.getElementById('status-text');

            statusText.innerText = text;

            if (state === 'connected') {
                badge.className = "inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-cyan-500/10 text-cyan-400 border border-cyan-500/30 transition-all duration-300 glow-neon";
                dot.className = "w-2 h-2 rounded-full bg-cyan-400 animate-pulse mr-2";
            } else if (state === 'connecting') {
                badge.className = "inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/30 transition-all duration-300";
                dot.className = "w-2 h-2 rounded-full bg-amber-400 animate-ping mr-2";
            } else {
                badge.className = "inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-slate-800 text-slate-400 border border-slate-700 transition-all duration-300";
                dot.className = "w-2 h-2 rounded-full bg-slate-500 mr-2";
            }
        }

        function updateVolume(val) {
            document.getElementById('volume-val').innerText = `${Math.round(val * 100)}%`;
            if (audioElement) audioElement.volume = val;
            if (isMuted && val > 0) toggleMute();
        }

        function toggleMute() {
            isMuted = !isMuted;
            const muteBtnIcon = document.getElementById('btn-mute-icon');
            if (audioElement) audioElement.muted = isMuted;

            if (isMuted) {
                muteBtnIcon.className = "fa-solid fa-volume-xmark text-lg text-rose-400";
            } else {
                muteBtnIcon.className = "fa-solid fa-volume-high text-lg text-slate-200";
            }
        }

        // VISUALIZER RENDERING LOGIC
        function setVisualizerMode(mode) {
            visualizerMode = mode;
            ['bars', 'wave', 'circle'].forEach(m => {
                const btn = document.getElementById(`vis-${m}-btn`);
                if (m === mode) {
                    btn.className = "px-2.5 py-1 rounded-md text-cyan-400 bg-slate-800 font-medium transition-all";
                } else {
                    btn.className = "px-2.5 py-1 rounded-md text-slate-400 hover:text-slate-200 font-medium transition-all";
                }
            });
        }

        function startVisualizer() {
            if (!analyser) return;

            const bufferLength = analyser.frequencyBinCount;
            const dataArray = new Uint8Array(bufferLength);

            function render() {
                if (!isPlaying) return;
                animFrameId = requestAnimationFrame(render);

                canvasCtx.clearRect(0, 0, canvas.width, canvas.height);

                if (visualizerMode === 'bars') {
                    analyser.getByteFrequencyData(dataArray);
                    renderBars(dataArray, bufferLength);
                } else if (visualizerMode === 'wave') {
                    analyser.getByteTimeDomainData(dataArray);
                    renderWave(dataArray, bufferLength);
                } else if (visualizerMode === 'circle') {
                    analyser.getByteFrequencyData(dataArray);
                    renderCircle(dataArray, bufferLength);
                }

                calculateStats(dataArray);
            }

            render();
        }

        function renderBars(dataArray, bufferLength) {
            const barWidth = (canvas.width / bufferLength) * 2.2;
            let x = 0;

            for (let i = 0; i < bufferLength; i++) {
                const barHeight = (dataArray[i] / 255) * canvas.height * 0.85;

                const gradient = canvasCtx.createLinearGradient(0, canvas.height, 0, 0);
                gradient.addColorStop(0, '#06b6d4');
                gradient.addColorStop(0.5, '#00f0ff');
                gradient.addColorStop(1, '#a855f7');

                canvasCtx.fillStyle = gradient;
                canvasCtx.fillRect(x, canvas.height - barHeight, barWidth - 2, barHeight);

                x += barWidth;
            }
        }

        function renderWave(dataArray, bufferLength) {
            canvasCtx.lineWidth = 3;
            canvasCtx.strokeStyle = '#00f0ff';
            canvasCtx.beginPath();

            const sliceWidth = canvas.width * 1.0 / bufferLength;
            let x = 0;

            for (let i = 0; i < bufferLength; i++) {
                const v = dataArray[i] / 128.0;
                const y = (v * canvas.height) / 2;

                if (i === 0) {
                    canvasCtx.moveTo(x, y);
                } else {
                    canvasCtx.lineTo(x, y);
                }

                x += sliceWidth;
            }

            canvasCtx.lineTo(canvas.width, canvas.height / 2);
            canvasCtx.stroke();
        }

        function renderCircle(dataArray, bufferLength) {
            const centerX = canvas.width / 2;
            const centerY = canvas.height / 2;
            const radius = Math.min(centerX, centerY) - 50;

            canvasCtx.beginPath();
            canvasCtx.arc(centerX, centerY, Math.max(10, radius - 20), 0, 2 * Math.PI);
            canvasCtx.strokeStyle = 'rgba(30, 41, 59, 0.8)';
            canvasCtx.lineWidth = 2;
            canvasCtx.stroke();

            for (let i = 0; i < bufferLength; i += 2) {
                const angle = (i / bufferLength) * Math.PI * 2;
                const barHeight = (dataArray[i] / 255) * 50;

                const x1 = centerX + Math.cos(angle) * radius;
                const y1 = centerY + Math.sin(angle) * radius;
                const x2 = centerX + Math.cos(angle) * (radius + barHeight);
                const y2 = centerY + Math.sin(angle) * (radius + barHeight);

                canvasCtx.strokeStyle = '#00f0ff';
                canvasCtx.lineWidth = 3;
                canvasCtx.beginPath();
                canvasCtx.moveTo(x1, y1);
                canvasCtx.lineTo(x2, y2);
                canvasCtx.stroke();
            }
        }

        function calculateStats(dataArray) {
            let maxVal = 0;
            for (let i = 0; i < dataArray.length; i++) {
                if (dataArray[i] > maxVal) maxVal = dataArray[i];
            }
            const dbPeak = Math.round((maxVal / 255) * 100);
            document.getElementById('stat-peak').innerText = `${dbPeak > 0 ? dbPeak : '0'} %`;
            document.getElementById('stat-latency').innerText = audioCtx ? `${Math.round(audioCtx.baseLatency * 1000 || 20)} ms` : '-- ms';
        }

        // Form Handlers & Configuration
        async function applyStreamUrl(e) {
            e.preventDefault();
            if (isPlaying) {
                await stopStream();
            }
            await startStream();
        }

        function changePort(port) {
            const input = document.getElementById('stream-url-input');
            let currentUrl = input.value;
            try {
                let urlObj = new URL(currentUrl);
                urlObj.port = port;
                input.value = urlObj.toString();
            } catch (e) {
                const defaultIp = window.location.hostname || '192.168.1.100';
                input.value = `http://${defaultIp}:${port}/stream`;
            }
            showToast(`Port set to ${port}`);
        }

        function handleTypeChange() {
            const type = document.getElementById('stream-type').value;
            const input = document.getElementById('stream-url-input');
            const defaultIp = window.location.hostname || '192.168.1.100';

            if (type === 'http-audio') {
                input.value = `http://${defaultIp}:8085/stream`;
            } else if (type === 'icecast') {
                input.value = `http://${defaultIp}:8000/stream.mp3`;
            } else if (type === 'demo') {
                input.value = `[Internal Synth Demo Engine]`;
            }
        }

        function setPreset(type, port, path) {
            const defaultIp = window.location.hostname || '192.168.1.100';
            document.getElementById('stream-type').value = type === 'icecast' ? 'icecast' : 'http-audio';
            document.getElementById('stream-url-input').value = `http://${defaultIp}:${port}${path}`;
            showToast(`Preset updated to port ${port}`);
        }

        function clearStreamUrl() {
            document.getElementById('stream-url-input').value = '';
        }

        // Utility Helpers
        function logMessage(msg) {
            const container = document.getElementById('log-container');
            const time = new Date().toLocaleTimeString();
            const div = document.createElement('div');
            div.innerHTML = `<span class="text-slate-600">[${time}]</span> ${msg}`;
            container.appendChild(div);
            container.scrollTop = container.scrollHeight;
        }

        function copyCode(id) {
            const codeText = document.getElementById(id).innerText;
            const textArea = document.createElement("textarea");
            textArea.value = codeText;
            document.body.appendChild(textArea);
            textArea.select();
            try {
                document.execCommand('copy');
                showToast("Command copied to clipboard!");
            } catch (err) {
                console.error('Copy failed', err);
            }
            document.body.removeChild(textArea);
        }

        function showToast(msg) {
            const toast = document.getElementById('toast');
            document.getElementById('toast-message').innerText = msg;
            toast.classList.remove('translate-y-20', 'opacity-0');
            toast.classList.add('translate-y-0', 'opacity-100');

            setTimeout(() => {
                toast.classList.add('translate-y-20', 'opacity-0');
                toast.classList.remove('translate-y-0', 'opacity-100');
            }, 3000);
        }
    </script>
</body>
</html>