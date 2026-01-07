@extends('admin.layout')

@section('content')
    <div class="page-header">
        <div>
            <h1>{{ $isEdit ? 'Edit' : 'Create' }} {{ $module['label'] }}</h1>
            <p>{{ $isEdit ? 'Update details for this record.' : 'Add a new record to this module.' }}</p>
        </div>
        <div class="page-actions">
            <a class="ghost-button" href="{{ route('admin.records', $module['slug']) }}">Back to list</a>
        </div>
    </div>

    <form class="form-card" method="POST" action="{{ $isEdit ? route('admin.update', ['module' => $module['slug'], 'id' => $recordId ?? $record->{$module['primary']} ?? '']) : route('admin.store', $module['slug']) }}">
        @csrf
        @if ($isEdit)
            @method('PUT')
        @endif

        <div class="form-grid">
            @foreach ($module['form'] as $fieldName)
                @php
                    $field = $module['fields'][$fieldName] ?? ['type' => 'text', 'label' => $fieldName];
                    $type = $field['type'] ?? 'text';
                    $label = $field['label'] ?? $fieldName;
                    $recordValue = data_get($record, $fieldName);
                    $rawValue = old($fieldName, $recordValue ?? ($field['default'] ?? ''));
                    $displayValue = $rawValue;
                    if ($type === 'datetime' && $rawValue) {
                        $displayValue = \Illuminate\Support\Carbon::parse($rawValue)->format('Y-m-d\\TH:i');
                    } elseif ($type === 'date' && $rawValue) {
                        $displayValue = \Illuminate\Support\Carbon::parse($rawValue)->format('Y-m-d');
                    } elseif ($type === 'time' && $rawValue) {
                        $displayValue = substr((string) $rawValue, 0, 5);
                    }
                    $required = !empty($field['required']);
                    $optionsForField = $options[$fieldName] ?? [];
                @endphp

                <div class="form-field {{ $errors->has($fieldName) ? 'has-error' : '' }}">
                    <label for="{{ $fieldName }}">{{ $label }}@if ($required)<span class="required">*</span>@endif</label>

                    @if ($type === 'textarea')
                        <textarea id="{{ $fieldName }}" name="{{ $fieldName }}" {{ $required ? 'required' : '' }}>{{ $displayValue }}</textarea>
                    @elseif ($type === 'select' || $type === 'enum')
                        <select id="{{ $fieldName }}" name="{{ $fieldName }}" {{ $required ? 'required' : '' }}>
                            <option value="">{{ $required ? 'Select an option' : 'Optional' }}</option>
                            @foreach ($optionsForField as $optionValue => $optionLabel)
                                <option value="{{ $optionValue }}" @selected((string) $optionValue === (string) $displayValue)>{{ $optionLabel }}</option>
                            @endforeach
                        </select>
                    @elseif ($type === 'boolean')
                        @php
                            $checked = old($fieldName, data_get($record, $fieldName) ?? ($field['default'] ?? false));
                        @endphp
                        <label class="switch">
                            <input type="checkbox" name="{{ $fieldName }}" value="1" {{ $checked ? 'checked' : '' }}>
                            <span class="slider"></span>
                        </label>
                    @elseif ($type === 'password')
                        <input id="{{ $fieldName }}" type="password" name="{{ $fieldName }}" {{ $required && !$isEdit ? 'required' : '' }} placeholder="{{ $isEdit ? 'Leave blank to keep current password' : '' }}">
                    @else
                        @php
                            $inputType = 'text';
                            $step = $field['step'] ?? null;
                            if ($type === 'email') {
                                $inputType = 'email';
                            } elseif ($type === 'number') {
                                $inputType = 'number';
                                $step = $step ?? 1;
                            } elseif ($type === 'decimal') {
                                $inputType = 'number';
                                $step = $step ?? 0.01;
                            } elseif ($type === 'date') {
                                $inputType = 'date';
                            } elseif ($type === 'datetime') {
                                $inputType = 'datetime-local';
                            } elseif ($type === 'time') {
                                $inputType = 'time';
                            }
                        @endphp
                        <input id="{{ $fieldName }}" type="{{ $inputType }}" name="{{ $fieldName }}" value="{{ $displayValue }}" {{ $required ? 'required' : '' }} @if ($step) step="{{ $step }}" @endif>
                    @endif

                    @if ($errors->has($fieldName))
                        <div class="field-error">{{ $errors->first($fieldName) }}</div>
                    @endif
                </div>
            @endforeach
        </div>

        <div class="form-actions">
            <button class="primary-button" type="submit">{{ $isEdit ? 'Save changes' : 'Create record' }}</button>
            <a class="ghost-button" href="{{ route('admin.records', $module['slug']) }}">Cancel</a>
        </div>
    </form>
@endsection
