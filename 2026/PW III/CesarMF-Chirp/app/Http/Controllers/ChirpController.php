<?php

namespace App\Http\Controllers;

use App\Models\Chirp;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;

class ChirpController extends Controller
{
    use AuthorizesRequests;
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
        $validated = $request->validate([
        'message' => 'required|string|max:255',
        ]);
        // Use the authenticated user
        auth()->user()->chirps()->create($validated);

        return redirect('/')->with('success', 'Your chirp has been posted!');
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
    $this->authorize('update', $chirp);
    return view('chirps.edit', compact('chirp'));
    }
    public function update(Request $request, Chirp $chirp)
    {
    $this->authorize('update', $chirp);

    // Validate
    $validated = $request->validate([
    'message' => 'required|string|max:255',
    ],
    [
        'message.required' => 'Please write something to Chirp!',
        'message.max' => 'Chirps must be 255 characters or less.',

    ]
    );
    // Update
    $chirp->update($validated);

    return redirect('/')->with('success', 'Chirp updated!');
    }

    

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Chirp $chirp) { 
        $this->authorize('update', $chirp);
        $chirp->delete();
    {
        return redirect('/')->with('success', 'Chirp deleted!');
    }
}
}