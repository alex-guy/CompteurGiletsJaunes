//
//  MainActivity
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Activité principale
//

package org.giletsjaunes.compteur;

import android.os.Bundle;
import android.os.StrictMode;
import android.support.annotation.NonNull;
import android.support.design.widget.BottomNavigationView;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.MenuItem;
import android.widget.FrameLayout;

import org.giletsjaunes.compteur.ui.tabaccueil.TabAccueilFragment;
import org.giletsjaunes.compteur.ui.tabapropos.TabAproposFragment;
import org.giletsjaunes.compteur.ui.tabcarte.TabCarteFragment;
import org.giletsjaunes.compteur.ui.tabchiffres.ChiffresRegionsFragment;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// classe MainActivity
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class MainActivity extends AppCompatActivity {

    FrameLayout frameLayout;
    FragmentManager fragmentManager;
    Fragment fragment;
    BottomNavigationView bottomNavigationView;
    String tab_courante = "";
    private final String TAG = "[CPTGJ] MainActivity";


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // listener sur les boutons du TabView, affiche les fragments
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    private BottomNavigationView.OnNavigationItemSelectedListener mOnNavigationItemSelectedListener
            = new BottomNavigationView.OnNavigationItemSelectedListener() {

        @Override
        public boolean onNavigationItemSelected(@NonNull MenuItem item) {
            switch (item.getItemId()) {

                case R.id.navigation_accueil:
                    if (!tab_courante.equals("accueil")) {
                        fragment = new TabAccueilFragment();
                        loadFragment(fragment);
                        tab_courante = "accueil";
                    }
                    return true;

                case R.id.navigation_chiffres:
                    if (!tab_courante.equals("chiffres")) {
                        fragment = new ChiffresRegionsFragment();
                        loadFragment(fragment);
                        tab_courante = "chiffres";
                    }
                    return true;

                case R.id.navigation_carte:
                    if (!tab_courante.equals("carte")) {
                        fragment = new TabCarteFragment();
                        loadFragment(fragment);
                        tab_courante = "carte";
                    }
                    return true;

                case R.id.navigation_apropos:
                    if (!tab_courante.equals("apropos")) {
                        fragment = new TabAproposFragment();
                        loadFragment(fragment);
                        tab_courante = "apropos";
                    }
                    return true;
            }
            return false;
        }
    };


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // affiche un fragment
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    private void loadFragment(Fragment fragment) {
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.frame_container, fragment,null);
        /* Comment this line and it should work!*/
        //transaction.addToBackStack(null);
        transaction.commit();
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onCreate
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // Pour autoriser les requetes POST depuis le thread principal
        StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
        StrictMode.setThreadPolicy(policy);

        // Suppression du titre de l'app
        getSupportActionBar().hide();

        // Initialisation du singleton
        Brain.initInstance(getString(R.string.cle_chiffrement));

        fragmentManager = getSupportFragmentManager();

        if(findViewById(R.id.frame_container)!=null){
            if(savedInstanceState!=null){
                return;
            }
        }
        bottomNavigationView = (BottomNavigationView) findViewById(R.id.navigation);
        bottomNavigationView.setOnNavigationItemSelectedListener(mOnNavigationItemSelectedListener);

        fragment = new TabAccueilFragment();
        loadFragment(fragment);
        tab_courante = "accueil";

    }

    @Override
    protected void onSaveInstanceState(Bundle b) {
        Log.d(TAG,"onSaveInstanceState ++++++++++++++++++++++++++++++++");
        super.onSaveInstanceState(b);
    }
}
