<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return redirect()->route('admin.index');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [AdminController::class, 'index'])->name('index');
    Route::get('{module}/create', [AdminController::class, 'create'])->name('create');
    Route::post('{module}', [AdminController::class, 'store'])->name('store');
    Route::get('{module}/{id}/edit', [AdminController::class, 'edit'])->name('edit');
    Route::put('{module}/{id}', [AdminController::class, 'update'])->name('update');
    Route::delete('{module}/{id}', [AdminController::class, 'destroy'])->name('destroy');
    Route::get('{module}', [AdminController::class, 'records'])->name('records');
});
