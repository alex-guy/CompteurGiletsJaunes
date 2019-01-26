//
//  TabAccueilFragment
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Première page : inscription et compteur total
//

package org.giletsjaunes.compteur.ui.tabaccueil;

import android.Manifest;
import android.content.Context;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.provider.Settings;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v4.content.ContextCompat;
import android.support.v7.app.AlertDialog;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.kaopiz.kprogresshud.KProgressHUD;
import com.karumi.dexter.Dexter;
import com.karumi.dexter.MultiplePermissionsReport;
import com.karumi.dexter.PermissionToken;
import com.karumi.dexter.listener.multi.MultiplePermissionsListener;
import org.giletsjaunes.compteur.Brain;
import org.giletsjaunes.compteur.R;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Fragment Accueil
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class TabAccueilFragment extends Fragment {

    public static TabAccueilFragment newInstance() {
        return new TabAccueilFragment();
    }

    double longitude = 0;
    double latitude = 0;
    private String uuid = "";
    private boolean inscription_realisee;
    private LocationManager locationManager;
    private final String TAG = "[CPTGJ] TabAccueil";
    private KProgressHUD hud;

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onCreateView
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.tab_accueil_fragment, container, false);
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onActivityCreated
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);

        // TODO: Use the ViewModel
        Log.i(TAG, "Tab accueil");

        inscription_realisee = false;

    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // onResume
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void onResume() {
        super.onResume();
        Log.i(TAG, "onResume");
        final Brain brain = Brain.getInstance();

        final ImageView bouton = getView().findViewById(R.id.imageView);

        // Connexion à Internet fonctionnelle
        if (brain.serveurPingue(getContext(), getString(R.string.ip_serveur))) {
            Log.i(TAG, "Reseau disponible et le serveur pingue");

            // Mise à jour du compteur total
            miseAJourCompteur();

            // Generation d'UUID unique avec la chaine ANDROID_ID comme graine
            String androidId = Settings.Secure.getString(getContext().getContentResolver(), Settings.Secure.ANDROID_ID);
            Log.e(TAG, "AndroidID: "+ androidId);

            uuid = UUID.nameUUIDFromBytes(androidId.getBytes()).toString();
            // Pour test
            //uuid = UUID.randomUUID().toString();
            Log.e(TAG, "UUID: " + uuid);

            // Verification si l'utilisateur existe
            if (brain.utilisateurExiste(uuid)) {
                Log.i(TAG, "L'utilisateur " + uuid + " existe !!!");
                afficheDejaInscript();
            } else {
                Log.i(TAG, "L'utilisateur " + uuid + " n'existe pas ...");
                View.OnClickListener clickListener = new View.OnClickListener() {
                    public void onClick(View v) {
                        if (v.equals(bouton)) {
                            clickGiletJaune();
                        }
                    }
                };
                bouton.setOnClickListener(clickListener);
            }


        } else {
            Log.e(TAG, "Reseau ou serveur NON disponible !!!");
            View.OnClickListener clickListener = new View.OnClickListener() {
                public void onClick(View v) {
                    if (v.equals(bouton)) {
                        brain.alertePasInternet(getContext());
                    }
                }
            };
            bouton.setOnClickListener(clickListener);
            brain.alertePasInternet(getContext());
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // affiche la date et commune d'inscription et cache le texte d'inscription
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void afficheDejaInscript() {
        Brain brain = Brain.getInstance();
        // Charge info utilisateur
        ArrayList<String> info_user = brain.chargeInformationsUtilisateur(uuid);
        Log.e(TAG, "last_seen: " + info_user.get(0));
        Log.e(TAG, "ville: " + info_user.get(1));
        // Mise à jour info sur UI
        TextView texte_inscription = getView().findViewById(R.id.texte_inscription);
        texte_inscription.setVisibility(View.INVISIBLE);
        TextView date_inscription = getView().findViewById(R.id.date_inscription);
        date_inscription.setVisibility(View.VISIBLE);
        date_inscription.setText("Inscription: " + brain.convertiDate(info_user.get(0)));
        TextView commune = getView().findViewById(R.id.commune);
        commune.setVisibility(View.VISIBLE);
        commune.setText("Commune: " + info_user.get(1));
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // met à jour le compteur de gilets jaunes
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void miseAJourCompteur() {
        Brain brain = Brain.getInstance();
        String total = brain.chargeTotal();
        TextView compteur = getView().findViewById(R.id.compteur);
        compteur.setText(total);
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // click sur le gilet jaune, affiche la fenètre de confirmation
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void clickGiletJaune() {
        AlertDialog.Builder adb = new AlertDialog.Builder(getContext());
        //adb.setView(getView());
        adb.setTitle("Clicker sur OK pour confirmer l'inscription");
        //adb.setIcon(android.R.drawable.ic_dialog_alert);
        adb.setPositiveButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                Log.i(TAG, "OK");
                confirmeClickGiletJaune();
            }
        });
        adb.setNegativeButton("Annuler", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                Log.i(TAG, "Annuler");
            }
        });
        adb.show();
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // listener associé à l'activation du GPS, appelle la fonction d'inscription
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    private final LocationListener locationListener = new LocationListener() {
        public void onLocationChanged(Location location) {
            Log.d(TAG, "onLocationChanged: " + location);
            longitude = location.getLongitude();
            latitude = location.getLatitude();
            inscriptionUtilisateur(longitude, latitude);
        }

        public void onStatusChanged(String provider, int status, Bundle extras) {
            Log.d(TAG, "onStatusChanged: " + provider + " / " + status + " / " + extras);

        }

        public void onProviderEnabled(String provider) {
            Log.d(TAG, "onProviderEnabled: " + provider);
        }

        public void onProviderDisabled(String provider) {
            Log.d(TAG, "onProviderDisabled: " + provider);
        }
    };


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // enregistre l'utilisateur en gilet jaune sur le serveur et affiche toast
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void inscriptionUtilisateur(double longitude, double latitude) {
        if (!inscription_realisee) {
            Log.e(TAG, "location, lon:" + longitude + " lat:" + latitude);
            Brain brain = Brain.getInstance();
            String message = "Une erreur est survenue durant l'inscription !";
            if (!uuid.equalsIgnoreCase("") && brain.inscriptionUtilisateur(uuid, String.valueOf(longitude), String.valueOf(latitude))) {
                message = "Inscription bien enregistrée !";
                inscription_realisee = true;
                final ImageView bouton = getView().findViewById(R.id.imageView);
                bouton.setOnClickListener(null);
                //SystemClock.sleep(5000);
                afficheDejaInscript();
                miseAJourCompteur();
                // Suppression du suivi de la position GPS
                if(locationManager != null) {
                    locationManager.removeUpdates(locationListener);
                    locationManager = null;
                }
                if(hud != null) {
                    hud.dismiss();
                }
            }
            Toast.makeText(getContext(), message, Toast.LENGTH_LONG).show();
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // click de confirmation inscription, demande les autorisations position GPS
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void confirmeClickGiletJaune() {

        // Demande des autorisations
        Dexter.withActivity(getActivity())
                .withPermissions(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
                .withListener(new MultiplePermissionsListener() {
                    @Override
                    public void onPermissionsChecked(MultiplePermissionsReport report) {
                        Log.i(TAG, "onPermissionsChecked");
                        lanceSurveillancePosition();
                    }

                    @Override
                    public void onPermissionRationaleShouldBeShown(List<com.karumi.dexter.listener.PermissionRequest> permissions, PermissionToken token) {
                        Log.i(TAG, "onPermissionRationaleShouldBeShown");
                        token.cancelPermissionRequest();
                        afficheInscriptionPositionInconnue();
                    }
                }).check();

    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // lance la récupération de la position GPS
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void lanceSurveillancePosition() {
        locationManager = (LocationManager) getContext().getApplicationContext().getSystemService(Context.LOCATION_SERVICE);

        // Affichage du message d'attente
        hud = KProgressHUD.create(getContext())
                .setStyle(KProgressHUD.Style.SPIN_INDETERMINATE)
                .show();

        Log.e(TAG, "ACCESS_FINE_LOCATION: " +  android.Manifest.permission.ACCESS_FINE_LOCATION);
        Log.e(TAG, "ACCESS_COARSE_LOCATION: " + android.Manifest.permission.ACCESS_COARSE_LOCATION);

        if (Build.VERSION.SDK_INT >= 23 &&
                ContextCompat.checkSelfPermission(getContext(), android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(getContext(), android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                Log.e(TAG, "Permissions FINE_LOCATION et/ou COARSE_LOCATION NON AUTORISEE ===============");
            return;
        }
        locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 2000, 10, locationListener);
        Handler handler = new Handler();

        // Procédure lancée dans 30 secondes, vérifie si l'inscription a été faite, et le cas contraire, demande confirmation
        // pour lancer l'inscription sans commune associée
        final Runnable r = new Runnable() {
            public void run() {
                Log.e(TAG, "fin 30 secondes, inscription realisee: " + inscription_realisee);
                if (!inscription_realisee) {
                    // L'inscription n'a pas été réalisée car le GPS ne répond pas,
                    afficheInscriptionPositionInconnue();
                 }
            }
        };
        handler.postDelayed(r, 30000);
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // affiche le dialog proposant de s'inscrire sans position connue
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void afficheInscriptionPositionInconnue() {
        AlertDialog.Builder adb = new AlertDialog.Builder(getContext());
        adb.setTitle("Impossible de déterminer votre position GPS !");
        adb.setMessage("Vous pouvez continuer l'inscription mais vous ne serez pas associé à une commune, ou vous pouvez annuler et renouveler votre inscription ultérieurement");
        adb.setIcon(android.R.drawable.ic_dialog_alert);
        adb.setPositiveButton("Continuer", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                // on lance l'inscription avec des coordonnées à zéro
                Log.i(TAG, "inscription GPS non fonctionnelle, inscription avec coordonnées à zéro ...");
                inscriptionUtilisateur(0.0, 0.0);
            }
        });
        adb.setNegativeButton("Annuler", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                Log.i(TAG, "Annuler inscription");
                if(hud != null) hud.dismiss();
            }
        });
        adb.show();
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        Log.e(TAG, "onSaveInstanceState ***********************");
    }
}