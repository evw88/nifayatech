@extends('admin.layout')

@section('content')
    <div class="page-header">
        <div>
            <h1>{{ $module['label'] }}</h1>
            <p>Manage {{ strtolower($module['label']) }} records.</p>
        </div>
        <div class="page-actions">
            @if ($module['allow_create'])
                <a class="primary-button" href="{{ route('admin.create', $module['slug']) }}">New {{ $module['label'] }}</a>
            @endif
        </div>
    </div>

    <form class="search-bar" method="GET" action="{{ route('admin.records', $module['slug']) }}">
        <input type="search" name="q" value="{{ $search }}" placeholder="Search {{ strtolower($module['label']) }}...">
        <button class="ghost-button" type="submit">Search</button>
        @if ($search)
            <a class="ghost-button" href="{{ route('admin.records', $module['slug']) }}">Clear</a>
        @endif
    </form>

    @if ($rows->count())
        <div class="table-card">
            <table>
                <thead>
                    <tr>
                        @foreach ($module['list'] as $fieldName)
                            <th>{{ $module['fields'][$fieldName]['label'] ?? $fieldName }}</th>
                        @endforeach
                        <th class="table-actions">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($rows as $row)
                        <tr>
                            @foreach ($module['list'] as $fieldName)
                                @php
                                    $field = $module['fields'][$fieldName] ?? ['type' => 'text'];
                                    $value = data_get($row, $fieldName);
                                    if (isset($relationMaps[$fieldName])) {
                                        $value = $relationMaps[$fieldName][$value] ?? $value;
                                    }
                                    if (($field['type'] ?? '') === 'boolean') {
                                        $value = $value ? 'Yes' : 'No';
                                    }
                                    if (($field['type'] ?? '') === 'textarea' && $value) {
                                        $value = \Illuminate\Support\Str::limit($value, 40);
                                    }
                                    if ($value === null || $value === '') {
                                        $value = '—';
                                    }
                                @endphp
                                <td data-label="{{ $module['fields'][$fieldName]['label'] ?? $fieldName }}">{{ $value }}</td>
                            @endforeach
                            <td class="table-actions">
                                @if ($module['allow_edit'])
                                    <a class="link-button" href="{{ route('admin.edit', ['module' => $module['slug'], 'id' => $row->__id]) }}">Edit</a>
                                @endif
                                @if ($module['allow_delete'])
                                    <form method="POST" action="{{ route('admin.destroy', ['module' => $module['slug'], 'id' => $row->__id]) }}" onsubmit="return confirm('Delete this record?');">
                                        @csrf
                                        @method('DELETE')
                                        <button class="link-button danger" type="submit">Delete</button>
                                    </form>
                                @endif
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>

        {{ $rows->onEachSide(1)->links('admin.pagination') }}
    @else
        <div class="empty-state">
            <h3>No records yet</h3>
            <p>Add the first {{ strtolower($module['label']) }} entry to get started.</p>
            @if ($module['allow_create'])
                <a class="primary-button" href="{{ route('admin.create', $module['slug']) }}">Create {{ $module['label'] }}</a>
            @endif
        </div>
    @endif
@endsection
