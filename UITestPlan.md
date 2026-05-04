# Quantum Mechanics Lab - UI/Interaction Test Plan

This manual test plan covers the core user interactions for the macOS/iOS application to verify stability, visual feedback, and state persistence.

## 1. Experiment Selection Stability
**Goal**: Ensure selecting different experiments correctly sets up the views and prevents crashing.
*   **Action**: Launch the app (iOS Simulator or macOS build).
*   **Action**: Open the sidebar / experiment list.
*   **Action**: Select "Infinite Square Well".
*   **Expected**: The 1D canvas is displayed. The density curve and potential walls look correct. No crashes.
*   **Action**: Select "Hydrogen Orbitals".
*   **Expected**: The 2D slice (or 3D view if implemented) of the orbital is displayed.
*   **Action**: Select "Double Slit 2D".
*   **Expected**: The Metal-backed 2D texture rendering canvas is displayed, showing a clear barrier with two slits. No crashes.

## 2. Playback Controls
**Goal**: Verify that time evolution responds to playback controls.
*   **Action**: Select the "Free Wavepacket" experiment.
*   **Action**: Tap the **Play** button.
*   **Expected**: The wavepacket moves to the right (positive initial momentum). The timeline/step count increments.
*   **Action**: Tap the **Pause** button.
*   **Expected**: The wavepacket stops moving.
*   **Action**: Tap the **Reset** button.
*   **Expected**: The wavepacket returns to its exact initial position. The time resets to 0.

## 3. Parameter Updates
**Goal**: Ensure that sliders update the simulation correctly and seamlessly.
*   **Action**: Select the "Harmonic Oscillator" experiment.
*   **Action**: Pause the simulation if it is playing.
*   **Action**: Adjust the "Mass" parameter via the inspector slider.
*   **Expected**: The wavefunction envelope immediately updates (becomes narrower or wider) as the slider moves. The potential curve updates if the mass affects the harmonic potential steepness.
*   **Action**: Adjust the "Initial Center" parameter.
*   **Expected**: The wavepacket shifts to the new center position instantly.

## 4. Custom Potential Presets (Save/Load/Delete)
**Goal**: Validate that users can draw potentials, save them, load them later, and delete them.
*   **Action**: Select the "Custom Potential" experiment.
*   **Action**: Use the pointer/touch to draw a completely random, distinct shape on the 1D canvas.
*   **Action**: Tap "Save Preset", enter the name "My Custom Well", and confirm.
*   **Expected**: The preset appears in the saved presets list.
*   **Action**: Tap the "Clear" or "Reset" button (or draw a new shape) to destroy the current drawing.
*   **Action**: Select the "My Custom Well" preset from the list and load it.
*   **Expected**: The previously drawn distinct shape is restored perfectly. The wavepacket automatically adjusts its observables based on the newly loaded potential.
*   **Action**: Swipe or click the delete option on the "My Custom Well" preset in the list.
*   **Expected**: The preset is removed from the list.
*   **Action**: Restart the app and check the preset list.
*   **Expected**: The deleted preset remains deleted (validating `UserDefaultsProjectStore` synchronization).

## 5. UI Validation Checklist (For Future Automation)
*   [ ] `testExperimentSelectionDoesNotCrash`
*   [ ] `testPlaybackTogglesEvolution`
*   [ ] `testParameterSliderUpdatesSnapshot`
*   [ ] `testCustomPotentialPresetLifecycle`
