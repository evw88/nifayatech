@extends('admin.layout')

@section('content')
    <div class="dashboard-hero">
        <div>
            <h1>Control Center</h1>
            <p>Manage containers, routes, fleet, workforce, recycling partners, and alerts from one place.</p>
        </div>
        <div class="hero-badge">nifayatech</div>
    </div>

    @foreach ($groups as $group)
        <div class="module-group">
            <div class="module-group-title">{{ $group['label'] }}</div>
            <div class="module-grid">
                @foreach ($group['modules'] as $slug => $module)
                    <a class="module-card" href="{{ route('admin.records', $slug) }}">
                        <div class="module-card-title">{{ $module['label'] }}</div>
                        <div class="module-card-meta">
                            <span class="module-card-count">{{ $counts[$slug] ?? '—' }}</span>
                            <span class="module-card-label">records</span>
                        </div>
                    </a>
                @endforeach
            </div>
        </div>
    @endforeach
@endsection
