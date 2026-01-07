@if ($paginator->hasPages())
    <nav class="pagination" role="navigation">
        @if ($paginator->onFirstPage())
            <span class="page-link is-disabled">Prev</span>
        @else
            <a class="page-link" href="{{ $paginator->previousPageUrl() }}" rel="prev">Prev</a>
        @endif

        <div class="page-numbers">
            @foreach ($elements as $element)
                @if (is_string($element))
                    <span class="page-ellipsis">{{ $element }}</span>
                @endif

                @if (is_array($element))
                    @foreach ($element as $page => $url)
                        @if ($page == $paginator->currentPage())
                            <span class="page-number is-active">{{ $page }}</span>
                        @else
                            <a class="page-number" href="{{ $url }}">{{ $page }}</a>
                        @endif
                    @endforeach
                @endif
            @endforeach
        </div>

        @if ($paginator->hasMorePages())
            <a class="page-link" href="{{ $paginator->nextPageUrl() }}" rel="next">Next</a>
        @else
            <span class="page-link is-disabled">Next</span>
        @endif
    </nav>
@endif
