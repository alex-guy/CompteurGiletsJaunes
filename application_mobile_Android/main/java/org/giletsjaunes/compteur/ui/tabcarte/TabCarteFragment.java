//
//  TabCarteFragment
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Troisième page : carte OpenStreetMap avec annotations
//

package org.giletsjaunes.compteur.ui.tabcarte;

import android.content.Context;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import org.giletsjaunes.compteur.Brain;
import org.giletsjaunes.compteur.R;
import org.osmdroid.api.IMapController;
import org.osmdroid.config.Configuration;
import org.osmdroid.events.DelayedMapListener;
import org.osmdroid.events.MapListener;
import org.osmdroid.events.ScrollEvent;
import org.osmdroid.events.ZoomEvent;
import org.osmdroid.library.BuildConfig;
import org.osmdroid.tileprovider.tilesource.TileSourceFactory;
import org.osmdroid.util.GeoPoint;
import org.osmdroid.views.MapView;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Fragment carte Open Street Map
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class TabCarteFragment extends Fragment {

    MapView map = null;
    private final String TAG = "[CPTGJ] TabCarte";

    public static TabCarteFragment newInstance() {
        return new TabCarteFragment();
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onCreateView
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        Log.e(TAG, "onCreateView");

        // OSM
        Context ctx = getContext();
        Configuration.getInstance().load(ctx, PreferenceManager.getDefaultSharedPreferences(ctx));
        Configuration.getInstance().setUserAgentValue(BuildConfig.APPLICATION_ID);

        return inflater.inflate(R.layout.tab_carte_fragment, container, false);
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onActivityCreated
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);

        Log.i(TAG,"Tab carte");
        final Brain brain = Brain.getInstance();

        // OSM
        map = (MapView) getView().findViewById(R.id.mapview);
        map.setTileSource(TileSourceFactory.MAPNIK);
        map.setMultiTouchControls(true);

        // On centre sur la France
        IMapController mapController = map.getController();
        //mapController.setZoom(7.1);
        mapController.setZoom(6.0);
        GeoPoint startPoint = new GeoPoint(46, 2.5);
        mapController.setCenter(startPoint);

        // Connexion à Internet fonctionnelle
        if(brain.serveurPingue(getContext(), getString(R.string.ip_serveur))) {

            // Le listener appelé a chaque scroll ou zoom
            map.addMapListener(new DelayedMapListener(new MapListener() {
                @Override
                public boolean onScroll(ScrollEvent event) {
                    Log.i(TAG, " onScroll, x,y: " + event.getX() + "," + event.getY());
                    //Toast.makeText(getActivity(), "onScroll", Toast.LENGTH_SHORT).show();
                    dessineAnnotations();

                    return true;
                }

                @Override
                public boolean onZoom(ZoomEvent event) {
                    Log.i(TAG, "onZoom, zoom: " + event.getZoomLevel());
                    dessineAnnotations();
                    return true;
                }
            }, 200));
        }
        else {
            brain.alertePasInternet(getContext());
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // zoom intelligent, dessine les annotations sur la carte
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    private void dessineAnnotations() {
        double zoom_level = map.getZoomLevelDouble();
        Log.i(TAG, "Zoom: " + zoom_level);

        Brain brain = Brain.getInstance();

        if (zoom_level >= 10) {
            brain.dessineAnnotationsCommunesSurLaCarte(map, getContext());
        } else if (zoom_level >= 8) {
            brain.dessineAnnotationsDepartementsSurLaCarte(map, getContext());
        } else {
            brain.dessineAnnotationsRegionsSurLaCarte(map, getContext());
        }
        // A garder sinon il faut toucher a la carte pour que les annotations apparaissent
        map.invalidate();
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onResume
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void onResume(){
        super.onResume();
       map.onResume();
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onPause
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void onPause(){
        super.onPause();
        map.onPause();
    }

}
