<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockInventory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class StockController extends Controller
{
    /**
     * GET - Ambil semua data
     */
    public function index()
    {
        $data = StockInventory::latest()->get();

        return response()->json([
            'status' => true,
            'message' => 'Data berhasil diambil',
            'data' => $data
        ], 200);
    }

    /**
     * POST - Tambah data
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nama' => 'required|string|max:255',
            'kuantitas' => 'required|integer',
            'unit' => 'required|string',
            'keterangan' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        $imagePath = null;

        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('barang', 'public');
        }

        $barang = StockInventory::create([
            'nama' => $request->nama,
            'kuantitas' => $request->kuantitas,
            'keterangan' => $request->keterangan,
            'unit' => $request->unit,
            'image' => $imagePath,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Data berhasil ditambahkan',
            'data' => $barang
        ], 201);
    }

    /**
     * GET - Detail berdasarkan ID
     */
    public function show(string $id)
    {
        // FIX: cukup pakai find($id), tidak perlu $column
        $barang = StockInventory::find($id);

        if (!$barang) {
            return response()->json([
                'status' => false,
                'message' => 'Data tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'status' => true,
            'message' => 'Detail data berhasil diambil',
            'data' => $barang
        ], 200);
    }

    /**
     * PUT/PATCH - Update data
     */
    public function update(Request $request, string $id)
    {
        $barang = StockInventory::find($id);

        if (!$barang) {
            return response()->json([
                'status' => false,
                'message' => 'Data tidak ditemukan'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'nama' => 'required|string|max:255',
            'kuantitas' => 'required|integer',
            'unit' => 'required|string',
            'keterangan' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        if ($request->hasFile('image')) {
            // hapus gambar lama jika ada
            if ($barang->image && Storage::disk('public')->exists($barang->image)) {
                Storage::disk('public')->delete($barang->image);
            }

            $barang->image = $request->file('image')->store('barang', 'public');
        }

        $barang->nama = $request->nama;
        $barang->kuantitas = $request->kuantitas;
        $barang->unit = $request->unit;
        $barang->keterangan = $request->keterangan;
        $barang->save();

        return response()->json([
            'status' => true,
            'message' => 'Data berhasil diupdate',
            'data' => $barang
        ], 200);
    }

    /**
     * DELETE - Hapus data
     */
    public function destroy(string $id)
    {
        // FIX: cukup pakai find($id), tidak perlu $column
        $barang = StockInventory::find($id);

        if (!$barang) {
            return response()->json([
                'status' => false,
                'message' => 'Data tidak ditemukan'
            ], 404);
        }

        // hapus gambar jika ada
        if ($barang->image && Storage::disk('public')->exists($barang->image)) {
            Storage::disk('public')->delete($barang->image);
        }

        $barang->delete();

        return response()->json([
            'status' => true,
            'message' => 'Data berhasil dihapus'
        ], 200);
    }
}