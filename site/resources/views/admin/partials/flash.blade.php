@if (session('status'))
    <div class="alert success">{{ session('status') }}</div>
@endif

@if ($errors->any())
    <div class="alert error">
        <div class="alert-title">Please fix the errors below</div>
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif
