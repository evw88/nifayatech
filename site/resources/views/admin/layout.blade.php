<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{{ $pageTitle ?? config('admin.title') }} | {{ config('admin.title') }}</title>
        <link rel="stylesheet" href="{{ asset('css/admin.css') }}">
    </head>
    <body class="admin-body">
        <div class="admin-shell">
            <aside class="admin-sidebar">
                <div class="brand">
                    <div class="brand-mark">AST</div>
                    <div class="brand-text">
                        <div class="brand-title">{{ config('admin.title') }}</div>
                        <div class="brand-sub">Waste Operations Suite</div>
                    </div>
                </div>
                <nav class="nav">
                    @foreach ($navGroups as $group)
                        <div class="nav-group">
                            <div class="nav-group-title">{{ $group['label'] }}</div>
                            @foreach ($group['modules'] as $slug => $module)
                                <a class="nav-link {{ $activeModule === $slug ? 'is-active' : '' }}" href="{{ route('admin.records', $slug) }}">
                                    <span>{{ $module['label'] }}</span>
                                </a>
                            @endforeach
                        </div>
                    @endforeach
                </nav>
            </aside>
            <main class="admin-main">
                <header class="admin-topbar">
                    <div class="topbar-title">{{ $pageTitle ?? 'Dashboard' }}</div>
                    <div class="topbar-actions">
                        <a class="ghost-button" href="{{ route('admin.index') }}">Dashboard</a>
                    </div>
                </header>
                <section class="admin-content">
                    @include('admin.partials.flash')
                    @yield('content')
                </section>
            </main>
        </div>
    </body>
</html>
