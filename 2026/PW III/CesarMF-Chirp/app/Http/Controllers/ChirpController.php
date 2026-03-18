<?php

namespace App\Http\Controllers;

use App\Models\Chirp;
use Illuminate\Http\Request;

class ChirpController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $chirps = Chirp::with('user')
            ->latest()
            ->take(50)  // Limit to 50 most recent chirps
            ->get();

        return view('home', ['chirps' => $chirps]);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        // Validate the request
        $validated = $request->validate([
        'message' => 'required|string|max:255',
        ], [
        'message.required' => 'Please write something to chirp!',
        'message.max' => 'Chirps must be 255 characters or less.',
        ]);
        // Create the chirp (no user for now - we'll add auth later)
        \App\Models\Chirp::create([
            'message' => $validated['message'],
            'user_id' => null, // We'll add authentication in lesson 11
        ]);

        // Redirect back to the feed
        return redirect('/')->with('success', 'Chirp created!');
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    public function edit(Chirp $chirp)
    {
    // We'll add authorization in lesson 11
    return view('chirps.edit', compact('chirp'));
    }
    public function update(Request $request, Chirp $chirp)
    {
    // Validate
    $validated = $request->validate([
    'message' => 'required|string|max:255',
    ]);
    // Update
    $chirp->update($validated);

    return redirect('/')->with('success', 'Chirp updated!');
    }

    

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Chirp $chirp) { $chirp->delete();
    {
        return redirect('/')->with('success', 'Chirp deleted!');
    }
}
}