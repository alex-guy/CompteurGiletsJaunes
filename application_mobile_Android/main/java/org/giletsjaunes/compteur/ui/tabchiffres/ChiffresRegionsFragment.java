//
//  ChiffresCommunesFragment
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Troisième page, premier écran : affichage des régions avec compteurs
//

package org.giletsjaunes.compteur.ui.tabchiffres;

import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentTransaction;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.TextView;
import org.giletsjaunes.compteur.Brain;
import org.giletsjaunes.compteur.R;
import org.giletsjaunes.compteur.Region;
import org.giletsjaunes.compteur.ui.RegionListViewAdapter;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Fragment des chiffres des régions
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class ChiffresRegionsFragment extends Fragment implements AdapterView.OnItemClickListener {

    private final String TAG = "[CPTGJ] ChiffresRegions";

    public static ChiffresRegionsFragment newInstance() {
        return new ChiffresRegionsFragment();
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onCreateView
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.tab_chiffres_fragment, container, false);
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onActivityCreated
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);

        Log.i(TAG,"Tab chiffres");

        Brain brain = Brain.getInstance();

        TextView titre = (TextView) getView().findViewById(R.id.nom_liste);
        titre.setText("Gilets Jaunes par région");

        // Connexion à Internet fonctionnelle
        if(brain.serveurPingue(getContext(), getString(R.string.ip_serveur))) {
            brain.chargeRegions();
            ListView listView = (ListView) getView().findViewById(R.id.liste_elements);
            RegionListViewAdapter adapter = new RegionListViewAdapter(getContext(), R.layout.region_item_layout, brain.liste_des_regions);
            listView.setAdapter(adapter);
            listView.setOnItemClickListener(this);
        }
        else {
            brain.alertePasInternet(getContext());
        }

    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // click sur une région, création du Fragment Departement
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        Brain brain = Brain.getInstance();

        Region regiontemp = brain.liste_des_regions.get(position);

        if(!regiontemp.id.equalsIgnoreCase("-1") && !regiontemp.id.equalsIgnoreCase("-2")) {
            Log.v(TAG, "Region choisie: " + regiontemp);
            Bundle arguments = new Bundle();
            ChiffresDepartementsFragment fragment = new ChiffresDepartementsFragment();
            fragment.setArguments(arguments);
            fragment.region = regiontemp;

            FragmentTransaction transaction = getActivity().getSupportFragmentManager().beginTransaction();
            transaction.replace(R.id.frame_container, fragment, null);
            /* Comment this line and it should work!*/
            transaction.addToBackStack(null);
            transaction.commit();
        }
    }
}
