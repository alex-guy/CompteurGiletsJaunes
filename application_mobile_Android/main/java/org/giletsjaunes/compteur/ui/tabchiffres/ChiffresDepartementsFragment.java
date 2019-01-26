//
//  ChiffresDepartementFragment
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Troisième page, deuxième écran : affichage des départements avec compteurs
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
import org.giletsjaunes.compteur.Departement;
import org.giletsjaunes.compteur.ui.DepartementListViewAdapter;
import org.giletsjaunes.compteur.R;
import org.giletsjaunes.compteur.Region;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Fragment des chiffres des départements
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class ChiffresDepartementsFragment extends Fragment implements AdapterView.OnItemClickListener {

    public Region region;
    private final String TAG = "[CPTGJ] ChiffresDepartement";

    public static ChiffresDepartementsFragment newInstance() { return new ChiffresDepartementsFragment(); }


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
        Log.i(TAG,"Tab chiffres départements");

        TextView titre = (TextView) getView().findViewById(R.id.nom_liste);
        titre.setText(R.string.chiffres_par_departement);

        Brain brain = Brain.getInstance();

        // Connexion à Internet fonctionnelle
        if(brain.serveurPingue(getContext(), getString(R.string.ip_serveur))) {
            brain.chargeDepartementsDeLaRegion(region.id);

            ListView listView = (ListView) getView().findViewById(R.id.liste_elements);
            DepartementListViewAdapter adapter = new DepartementListViewAdapter(getContext(), R.layout.region_item_layout, brain.liste_des_departements);
            listView.setAdapter(adapter);
            listView.setOnItemClickListener(this);
        }
        else {
            brain.alertePasInternet(getContext());
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // click sur un département, creation du fragment Communes
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        Brain brain = Brain.getInstance();

        Departement departementtemp = brain.liste_des_departements.get(position);

        Log.v(TAG, "Département choisi: " + departementtemp);
        Bundle arguments = new Bundle();
        ChiffresCommunesFragment fragment = new ChiffresCommunesFragment();
        fragment.setArguments(arguments);
        fragment.departement = departementtemp;

        FragmentTransaction transaction = getActivity().getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.frame_container, fragment,null);
        /* Comment this line and it should work!*/
        transaction.addToBackStack(null);
        transaction.commit();
    }

}
