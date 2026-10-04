package com.example.mahj_app

import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                    val fields = listOf(
                        Place.Field.DISPLAY_NAME,
                        Place.Field.FORMATTED_ADDRESS,
                        Place.Field.LOCATION,
                        Place.Field.ADDRESS_COMPONENTS,
                    )

                    val fetchRequest = FetchPlaceRequest.builder(
                        prediction.placeId,
                        fields,
                    ).build()

                    client.fetchPlace(fetchRequest)
                        .addOnSuccessListener { fetchResponse ->
                            val place = fetchResponse.place
                            val location = place.location
                            if (location != null) {
                                val name = place.displayName?.trim().orEmpty()
                                val address =
                                    place.formattedAddress?.trim().orEmpty()
                                val predictionLabel =
                                    prediction.getFullText(null).toString().trim()

                                val label = when {
                                    name.isNotEmpty() &&
                                        address.isNotEmpty() &&
                                        !address.contains(
                                            name,
                                            ignoreCase = true,
                                        ) -> "$name, $address"
                                    address.isNotEmpty() -> address
                                    name.isNotEmpty() -> name
                                    predictionLabel.isNotEmpty() ->
                                        predictionLabel
                                    else -> ""
                                }

                                if (label.isNotEmpty()) {
                                    val components =
                                        place.addressComponents
                                            ?.asList()
                                            .orEmpty()

                                    fun component(
                                        vararg wantedTypes: String,
                                    ): String {
                                        for (component in components) {
                                            if (
                                                wantedTypes.any {
                                                    component.types.contains(it)
                                                }
                                            ) {
                                                return component.name
                                            }
                                        }
                                        return ""
                                    }

                                    rows[index] = mapOf(
                                        "label" to label,
                                        "latitude" to location.latitude,
                                        "longitude" to location.longitude,
                                        "city" to component(
                                            "locality",
                                            "postal_town",
                                        ),
                                        "state" to component(
                                            "administrative_area_level_1",
                                        ),
                                        "zip_code" to component(
                                            "postal_code",
                                        ),
                                    )
                                }
                            }
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
}
