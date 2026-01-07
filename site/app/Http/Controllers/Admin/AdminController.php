<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    public function index()
    {
        $modules = config('admin.modules');
        $groups = $this->navGroups();
        $counts = [];

        foreach ($modules as $slug => $module) {
            try {
                $counts[$slug] = DB::table($module['table'])->count();
            } catch (\Throwable $e) {
                $counts[$slug] = null;
            }
        }

        return view('admin.index', [
            'title' => config('admin.title'),
            'groups' => $groups,
            'navGroups' => $groups,
            'counts' => $counts,
            'activeModule' => null,
            'pageTitle' => 'Dashboard',
        ]);
    }

    public function records(Request $request, string $module)
    {
        $moduleConfig = $this->moduleConfig($module);
        $query = DB::table($moduleConfig['table']);

        $search = trim((string) $request->query('q', ''));
        if ($search !== '' && !empty($moduleConfig['searchable'])) {
            $query->where(function ($builder) use ($moduleConfig, $search) {
                foreach ($moduleConfig['searchable'] as $field) {
                    $builder->orWhere($field, 'like', '%' . $search . '%');
                }
            });
        }

        $orderField = $moduleConfig['order_by']['field']
            ?? $moduleConfig['primary']
            ?? ($moduleConfig['list'][0] ?? null);
        $orderDirection = $moduleConfig['order_by']['direction'] ?? 'desc';
        if ($orderField) {
            $query->orderBy($orderField, $orderDirection);
        }

        $rows = $query->paginate($moduleConfig['per_page'])->withQueryString();
        $rows->setCollection(
            $rows->getCollection()->map(function ($row) use ($moduleConfig) {
                $row->__id = $this->rowKey($row, $moduleConfig);
                return $row;
            })
        );

        return view('admin.list', [
            'module' => $moduleConfig,
            'rows' => $rows,
            'search' => $search,
            'relationMaps' => $this->relationMaps($moduleConfig),
            'navGroups' => $this->navGroups(),
            'activeModule' => $moduleConfig['slug'],
            'pageTitle' => $moduleConfig['label'],
        ]);
    }

    public function create(string $module)
    {
        $moduleConfig = $this->moduleConfig($module);
        if (!$moduleConfig['allow_create']) {
            abort(404);
        }

        return view('admin.form', [
            'module' => $moduleConfig,
            'record' => null,
            'options' => $this->fieldOptions($moduleConfig),
            'isEdit' => false,
            'navGroups' => $this->navGroups(),
            'activeModule' => $moduleConfig['slug'],
            'pageTitle' => 'Create ' . $moduleConfig['label'],
        ]);
    }

    public function store(Request $request, string $module)
    {
        $moduleConfig = $this->moduleConfig($module);
        if (!$moduleConfig['allow_create']) {
            abort(404);
        }

        $request->validate($this->validationRules($moduleConfig, 'create'));
        $data = $this->buildPayload($request, $moduleConfig, 'create');
        DB::table($moduleConfig['table'])->insert($data);

        return redirect()
            ->route('admin.records', $moduleConfig['slug'])
            ->with('status', $moduleConfig['label'] . ' created.');
    }

    public function edit(string $module, string $id)
    {
        $moduleConfig = $this->moduleConfig($module);
        if (!$moduleConfig['allow_edit']) {
            abort(404);
        }

        $query = DB::table($moduleConfig['table']);
        $this->applyKeyConstraint($query, $moduleConfig, $id);
        $record = $query->first();

        if (!$record) {
            abort(404);
        }

        return view('admin.form', [
            'module' => $moduleConfig,
            'record' => $record,
            'recordId' => $this->rowKey($record, $moduleConfig),
            'options' => $this->fieldOptions($moduleConfig),
            'isEdit' => true,
            'navGroups' => $this->navGroups(),
            'activeModule' => $moduleConfig['slug'],
            'pageTitle' => 'Edit ' . $moduleConfig['label'],
        ]);
    }

    public function update(Request $request, string $module, string $id)
    {
        $moduleConfig = $this->moduleConfig($module);
        if (!$moduleConfig['allow_edit']) {
            abort(404);
        }

        $request->validate($this->validationRules($moduleConfig, 'update'));
        $data = $this->buildPayload($request, $moduleConfig, 'update');

        $query = DB::table($moduleConfig['table']);
        $this->applyKeyConstraint($query, $moduleConfig, $id);
        $query->update($data);

        return redirect()
            ->route('admin.records', $moduleConfig['slug'])
            ->with('status', $moduleConfig['label'] . ' updated.');
    }

    public function destroy(string $module, string $id)
    {
        $moduleConfig = $this->moduleConfig($module);
        if (!$moduleConfig['allow_delete']) {
            abort(404);
        }

        $query = DB::table($moduleConfig['table']);
        $this->applyKeyConstraint($query, $moduleConfig, $id);
        $query->delete();

        return redirect()
            ->route('admin.records', $moduleConfig['slug'])
            ->with('status', $moduleConfig['label'] . ' deleted.');
    }

    protected function moduleConfig(string $slug): array
    {
        $modules = config('admin.modules');
        if (!isset($modules[$slug])) {
            abort(404);
        }

        $module = $modules[$slug];
        $module['slug'] = $slug;
        $module['primary'] = $module['primary'] ?? null;
        $module['composite'] = $module['composite'] ?? [];
        $module['allow_create'] = $module['allow_create'] ?? true;
        $module['allow_edit'] = $module['allow_edit'] ?? true;
        $module['allow_delete'] = $module['allow_delete'] ?? true;
        $module['per_page'] = $module['per_page'] ?? 15;
        $module['searchable'] = $module['searchable'] ?? [];

        return $module;
    }

    protected function navGroups(): array
    {
        $modules = config('admin.modules');
        $groups = [];

        foreach ($modules as $slug => $module) {
            $group = $module['group'] ?? 'General';
            if (!isset($groups[$group])) {
                $groups[$group] = [
                    'label' => $group,
                    'modules' => [],
                ];
            }
            $groups[$group]['modules'][$slug] = array_merge($module, ['slug' => $slug]);
        }

        return $groups;
    }

    protected function fieldOptions(array $module): array
    {
        $options = [];
        foreach ($module['form'] as $fieldName) {
            $field = $module['fields'][$fieldName] ?? null;
            if (!$field) {
                continue;
            }
            $type = $field['type'] ?? 'text';
            if ($type === 'select' || $type === 'enum') {
                if (!empty($field['relation'])) {
                    $options[$fieldName] = $this->relationOptions($field['relation']);
                } else {
                    $options[$fieldName] = $field['options'] ?? [];
                }
            }
        }

        return $options;
    }

    protected function relationMaps(array $module): array
    {
        $maps = [];
        foreach ($module['list'] as $fieldName) {
            $field = $module['fields'][$fieldName] ?? null;
            if ($field && !empty($field['relation'])) {
                $maps[$fieldName] = $this->relationOptions($field['relation']);
            }
        }

        return $maps;
    }

    protected function relationOptions(array $relation): array
    {
        $query = DB::table($relation['table']);
        $orderField = $relation['order_by'] ?? $relation['label'];
        if ($orderField) {
            $query->orderBy($orderField);
        }

        return $query->pluck($relation['label'], $relation['key'])->toArray();
    }

    protected function validationRules(array $module, string $mode): array
    {
        $rules = [];

        foreach ($module['form'] as $fieldName) {
            $field = $module['fields'][$fieldName] ?? null;
            if (!$field || !empty($field['readonly'])) {
                continue;
            }

            $type = $field['type'] ?? 'text';
            if ($type === 'password') {
                $rules[$fieldName] = $mode === 'create' ? 'required|min:6' : 'nullable|min:6';
                continue;
            }

            $parts = [];
            if (!empty($field['required'])) {
                $parts[] = 'required';
            } else {
                $parts[] = 'nullable';
            }

            if ($type === 'email') {
                $parts[] = 'email';
            } elseif ($type === 'number') {
                $parts[] = 'integer';
            } elseif ($type === 'decimal') {
                $parts[] = 'numeric';
            } elseif ($type === 'date' || $type === 'datetime') {
                $parts[] = 'date';
            } elseif ($type === 'time') {
                $parts[] = 'date_format:H:i';
            } elseif ($type === 'boolean') {
                $parts[] = 'boolean';
            }

            $rules[$fieldName] = implode('|', $parts);
        }

        return $rules;
    }

    protected function buildPayload(Request $request, array $module, string $mode): array
    {
        $data = [];

        foreach ($module['form'] as $fieldName) {
            $field = $module['fields'][$fieldName] ?? null;
            if (!$field || !empty($field['readonly'])) {
                continue;
            }

            $type = $field['type'] ?? 'text';
            if ($type === 'password') {
                $value = $request->input($fieldName);
                if ($mode === 'update' && ($value === null || $value === '')) {
                    continue;
                }
                if ($value !== null && $value !== '') {
                    $data[$fieldName] = Hash::make($value);
                }
                continue;
            }

            if ($type === 'boolean') {
                $data[$fieldName] = $request->boolean($fieldName);
                continue;
            }

            $value = $request->input($fieldName);
            if ($value === '' || $value === null) {
                if ($mode === 'create' && array_key_exists('default', $field)) {
                    $value = $field['default'];
                } else {
                    $value = null;
                }
            }
            $data[$fieldName] = $value;
        }

        return $this->applyComputed($data, $module);
    }

    protected function applyComputed(array $data, array $module): array
    {
        if (empty($module['computed'])) {
            return $data;
        }

        foreach ($module['computed'] as $field => $rule) {
            if (($rule['type'] ?? null) === 'point') {
                $latField = $rule['lat'] ?? null;
                $lngField = $rule['lng'] ?? null;
                if ($latField && $lngField && isset($data[$latField], $data[$lngField])) {
                    $lat = (float) $data[$latField];
                    $lng = (float) $data[$lngField];
                    $data[$field] = DB::raw('POINT(' . $lng . ', ' . $lat . ')');
                }
            }
        }

        return $data;
    }

    protected function rowKey(object $row, array $module): string
    {
        if (!empty($module['composite'])) {
            $parts = [];
            foreach ($module['composite'] as $key) {
                $parts[] = (string) data_get($row, $key);
            }
            return implode('--', $parts);
        }

        if (!empty($module['primary'])) {
            return (string) data_get($row, $module['primary']);
        }

        return '';
    }

    protected function applyKeyConstraint($query, array $module, string $id): void
    {
        if (!empty($module['composite'])) {
            $parts = explode('--', $id);
            foreach ($module['composite'] as $index => $key) {
                if (isset($parts[$index])) {
                    $query->where($key, $parts[$index]);
                }
            }
            return;
        }

        if (!empty($module['primary'])) {
            $query->where($module['primary'], $id);
        }
    }
}
