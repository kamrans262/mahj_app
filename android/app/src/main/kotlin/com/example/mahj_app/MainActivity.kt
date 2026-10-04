package com.example.mahj_app

import android.location.Geocoder
import android.location.Location
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.CircularBounds
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import com.google.android.libraries.places.api.net.SearchNearbyRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private companion object {
        const val PLACES_CHANNEL = "mahj/places"
    }

    private var placesClient: PlacesClient? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val apiKey = BuildConfig.GOOGLE_MAPS_API_KEY
        if (apiKey.isNotBlank()) {
            if (!Places.isInitialized()) {
                Places.initializeWithNewPlacesApiEnabled(
                    applicationContext,
                    apiKey,
                )
            }
            placesClient = Places.createClient(this)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PLACES_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "search" -> {
                    val query = call.argument<String>("query")?.trim().orEmpty()
                    if (query.length < 2) {
                        result.success(emptyList<Map<String, Any?>>())
                    } else {
                        autocompletePlaces(query, result)
                    }
                }
                "resolveLocation" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    if (latitude == null || longitude == null) {
                        result.error(
                            "invalid_coordinates",
                            "A valid map coordinate is required.",
                            null,
                        )
                    } else {
                        resolveTappedLocation(latitude, longitude, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun autocompletePlaces(
        query: String,
        result: MethodChannel.Result,
    ) {
        val client = placesClient
        if (client == null) {
            result.error(
                "places_not_configured",
                "Google Places is not configured for this Android build.",
                null,
            )
            return
        }

        val request = FindAutocompletePredictionsRequest.builder()
            .setQuery(query)
            .build()

        client.findAutocompletePredictions(request)
            .addOnSuccessListener { response ->
                val predictions = response.autocompletePredictions.take(5)
                if (predictions.isEmpty()) {
                    result.success(emptyList<Map<String, Any?>>())
                    return@addOnSuccessListener
                }

                val rows = arrayOfNulls<Map<String, Any?>>(predictions.size)
                var remaining = predictions.size

                fun finishOne() {
                    remaining -= 1
                    if (remaining == 0) {
                        result.success(rows.filterNotNull())
                    }
                }

                predictions.forEachIndexed { index, prediction ->
                    val fetchRequest = FetchPlaceRequest.builder(
                        prediction.placeId,
                        placeFields(),
                    ).build()

                    client.fetchPlace(fetchRequest)
                        .addOnSuccessListener { fetchResponse ->
                            rows[index] = placeToMap(
                                fetchResponse.place,
                                prediction.getFullText(null)
                                    .toString()
                                    .trim(),
                            )
                            finishOne()
                        }
                        .addOnFailureListener {
                            finishOne()
                        }
                }
            }
            .addOnFailureListener { error ->
                result.error(
                    "places_autocomplete_failed",
                    error.message ?: "Google Places autocomplete failed.",
                    null,
                )
            }
    }

    private fun resolveTappedLocation(
        latitude: Double,
        longitude: Double,
        result: MethodChannel.Result,
    ) {
        val client = placesClient
        if (client == null) {
            reverseGeocode(latitude, longitude, result)
            return
        }

        val center = LatLng(latitude, longitude)
        val circle = CircularBounds.newInstance(center, 150.0)
        val request = SearchNearbyRequest.builder(
            circle,
            placeFields(),
        )
            .setMaxResultCount(10)
            .build()

        client.searchNearby(request)
            .addOnSuccessListener { response ->
                val nearest = response.places
                    .mapNotNull { place ->
                        val location = place.location
                            ?: return@mapNotNull null
                        val distance = FloatArray(1)
                        Location.distanceBetween(
                            latitude,
                            longitude,
                            location.latitude,
                            location.longitude,
                            distance,
                        )
                        Triple(place, distance[0], location)
                    }
                    .minByOrNull { it.second }

                if (nearest != null && nearest.second <= 150f) {
                    val mapped = placeToMap(nearest.first)
                    if (mapped != null) {
                        result.success(mapped)
                        return@addOnSuccessListener
                    }
                }

                reverseGeocode(latitude, longitude, result)
            }
            .addOnFailureListener {
                reverseGeocode(latitude, longitude, result)
            }
    }

    private fun reverseGeocode(
        latitude: Double,
        longitude: Double,
        result: MethodChannel.Result,
    ) {
        Thread {
            try {
                val geocoder = Geocoder(this, Locale.getDefault())
                @Suppress("DEPRECATION")
                val addresses = geocoder.getFromLocation(
                    latitude,
                    longitude,
                    1,
                )
                val address = addresses?.firstOrNull()

                if (address == null) {
                    runOnUiThread { result.success(null) }
                    return@Thread
                }

                val label = address.featureName
                    ?.takeIf {
                        it.isNotBlank() &&
                            !it.equals(address.thoroughfare, ignoreCase = true)
                    }
                    ?.let { feature ->
                        val full = address.getAddressLine(0).orEmpty()
                        if (
                            full.isNotBlank() &&
                            !full.contains(feature, ignoreCase = true)
                        ) {
                            "$feature, $full"
                        } else {
                            full.ifBlank { feature }
                        }
                    }
                    ?: address.getAddressLine(0)
                    ?: listOfNotNull(
                        address.thoroughfare,
                        address.subLocality,
                        address.locality,
                    ).joinToString(", ")

                val row = mapOf(
                    "label" to label,
                    "latitude" to latitude,
                    "longitude" to longitude,
                    "city" to (address.locality ?: ""),
                    "state" to (address.adminArea ?: ""),
                    "zip_code" to (address.postalCode ?: ""),
                )

                runOnUiThread { result.success(row) }
            } catch (_: Throwable) {
                runOnUiThread { result.success(null) }
            }
        }.start()
    }

    private fun placeFields(): List<Place.Field> {
        return listOf(
            Place.Field.DISPLAY_NAME,
            Place.Field.FORMATTED_ADDRESS,
            Place.Field.LOCATION,
            Place.Field.ADDRESS_COMPONENTS,
        )
    }

    private fun placeToMap(
        place: Place,
        fallbackLabel: String = "",
    ): Map<String, Any?>? {
        val location = place.location ?: return null
        val name = place.displayName?.trim().orEmpty()
        val address = place.formattedAddress?.trim().orEmpty()

        val label = when {
            name.isNotEmpty() &&
                address.isNotEmpty() &&
                !address.contains(name, ignoreCase = true) ->
                "$name, $address"
            address.isNotEmpty() -> address
            name.isNotEmpty() -> name
            fallbackLabel.isNotEmpty() -> fallbackLabel
            else -> return null
        }

        val components = place.addressComponents?.asList().orEmpty()

        fun component(vararg wantedTypes: String): String {
            for (component in components) {
                if (wantedTypes.any { component.types.contains(it) }) {
                    return component.name
                }
            }
            return ""
        }

        return mapOf(
            "label" to label,
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "city" to component("locality", "postal_town"),
            "state" to component("administrative_area_level_1"),
            "zip_code" to component("postal_code"),
        )
    }
}
