//
//  ChiffresCommunesFragment
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Troisième page, troisième écran : affichage des communes avec compteurs
//

package org.giletsjaunes.compteur.ui.tabchiffres;

import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ListView;
import android.widget.TextView;
import org.giletsjaunes.compteur.Brain;
import org.giletsjaunes.compteur.ui.CommuneListViewAdapter;
import org.giletsjaunes.compteur.Departement;
import org.giletsjaunes.compteur.R;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Fragment des chiffres des communes
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class ChiffresCommunesFragment extends Fragment {

    public Departement departement;
    private final String TAG = "[CPTGJ] ChiffresCommunes";

    public static ChiffresCommunesFragment newInstance() {
        return new ChiffresCommunesFragment();
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
        // TODO: Use the ViewModel
        Log.i(TAG,"Tab chiffres communes");

        TextView titre = (TextView) getView().findViewById(R.id.nom_liste);
        titre.setText(R.string.chiffres_par_commune);

        Brain brain = Brain.getInstance();

        // Connexion à Internet fonctionnelle
        if(brain.serveurPingue(getContext(), getString(R.string.ip_serveur))) {
            brain.chargeCommunesDuDepartement(departement.id);
            ListView listView = (ListView) getView().findViewById(R.id.liste_elements);
            CommuneListViewAdapter adapter = new CommuneListViewAdapter(getContext(), R.layout.region_item_layout, brain.liste_des_communes);
            listView.setAdapter(adapter);
        }
        else {
            brain.alertePasInternet(getContext());
        }
    }
}
