//
//  Brain
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Singleton contenant le code métier de l'application et différentes fonctions utilitaires
//

package org.giletsjaunes.compteur;

import android.content.Context;
import android.content.DialogInterface;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.SystemClock;
import android.support.v7.app.AlertDialog;
import android.util.Log;
import org.json.JSONException;
import org.json.JSONObject;
import org.osmdroid.api.IGeoPoint;
import org.osmdroid.util.GeoPoint;
import org.osmdroid.views.MapView;
import org.osmdroid.views.overlay.Marker;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.TimeZone;

import javax.net.ssl.HttpsURLConnection;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Classe Brain
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class Brain {

    private static Brain instance;

    public List<Region> liste_des_regions;
    public List<Departement> liste_des_departements;
    public List<Commune> liste_des_communes;

    private final String TAG = "[CPTGJ] Brain";
    private final String SERVEUR = "https://gj.tetalab.org:42443";
    private String cle_chiffrement = "";

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Méthode d'instance, crée le singleton
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public static void initInstance(String cle)
    {
        // Singleton
        if (instance == null)
        {
            instance = new Brain();
            instance.cle_chiffrement = cle;
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Renvoi le singleton
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public static Brain getInstance()
    {
        return instance;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Constructeur
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    private Brain() {
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Envoi une requete HTTP POST et renvoi la réponse
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public String appelPOST(String requestURL, String postDataParams) {
        URL url;
        Log.i(TAG, "Appel POST, requestURL:" + requestURL);
        Log.i(TAG, "Appel POST, postDataParams:" + postDataParams);
        String response = "";
        try {
            url = new URL(requestURL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000);
            conn.setConnectTimeout(15000);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);
            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(postDataParams);
            writer.flush();
            writer.close();
            os.close();
            int responseCode=conn.getResponseCode();
            //Log.e(TAG, "Reponse:" + responseCode);
            if (responseCode == HttpsURLConnection.HTTP_OK) {
                String line;
                BufferedReader br=new BufferedReader(new InputStreamReader(conn.getInputStream()));
                while ((line=br.readLine()) != null) {
                    response+=line;
                }
            }
            else {
                Log.e(TAG, "Erreur:" + responseCode);
                response="";
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return response;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Charge le nombre total de gilets jaunes
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public String chargeTotal() {
        String resultat = appelPOST(SERVEUR + "/regions/total", "");
        String total = "";
        Log.i(TAG,"resultat: " + resultat);
        try {
            JSONObject json = new JSONObject(resultat);
            JSONObject args = json.getJSONObject("args");
            total = args.getString("total");
            Log.i(TAG, "total: " + total);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return total;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Charge les régions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void chargeRegions() {
        String resultat = appelPOST(SERVEUR + "/regions/list", "");
        //Log.i(TAG,"resultat: " + resultat);
        liste_des_regions = new ArrayList<Region>(100);
        try {
            JSONObject json = new JSONObject(resultat);
            JSONObject args = json.getJSONObject("args");
            Iterator<String> iter = args.keys();
            while (iter.hasNext()) {
                String key = iter.next();
                JSONObject value = (JSONObject) args.get(key);
                //Log.i(TAG, "key: " + key + " value:" + value + " nom:" + value.get("nom") );
                Region region = new Region(key, value.getString("nom"), value.getString("cpt"), value.getString("lon"), value.getString("lat"));
                liste_des_regions.add(region);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Collections.sort(liste_des_regions, new Comparator<Region>(){
            public int compare(Region obj1, Region obj2) {
                int sComp = Integer.valueOf(obj2.nombre_total).compareTo(Integer.valueOf(obj1.nombre_total));
                if (sComp != 0) { return sComp; }
                return obj1.nom.compareTo(obj2.nom);
            }
        });
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Charge les départements d'une région donnée
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void chargeDepartementsDeLaRegion(String rgid) {
        String resultat = appelPOST(SERVEUR + "/departements/list", "rgid=" + rgid);
        //Log.i(TAG,"resultat: " + resultat);
        liste_des_departements = new ArrayList<Departement>(200);
        try {
            JSONObject json = new JSONObject(resultat);
            JSONObject args = json.getJSONObject("args");
            Iterator<String> iter = args.keys();
            while (iter.hasNext()) {
                String key = iter.next();
                JSONObject value = (JSONObject) args.get(key);
                //Log.i(TAG, "key: " + key + " value:" + value + " nom:" + value.get("nom") );
                Departement departement = new Departement(key, value.getString("nom"), value.getString("cpt"), value.getString("lon"), value.getString("lat"));
                liste_des_departements.add(departement);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Collections.sort(liste_des_departements, new Comparator<Departement>(){
            public int compare(Departement obj1, Departement obj2) {
                int sComp = Integer.valueOf(obj2.nombre_total).compareTo(Integer.valueOf(obj1.nombre_total));
                if (sComp != 0) { return sComp; }
                return obj1.nom.compareTo(obj2.nom);
            }
        });
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Charge les communes d'un département donné
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void chargeCommunesDuDepartement(String dgid) {
        String resultat = appelPOST(SERVEUR + "/communes/list", "dgid=" + dgid);
        //Log.i(TAG,"resultat: " + resultat);
        liste_des_communes = new ArrayList<Commune>(500);
        try {
            JSONObject json = new JSONObject(resultat);
            JSONObject args = json.getJSONObject("args");
            Iterator<String> iter = args.keys();
            while (iter.hasNext()) {
                String key = iter.next();
                JSONObject value = (JSONObject) args.get(key);
                //Log.i(TAG, "key: " + key + " value:" + value + " nom:" + value.get("nom") );
                Commune commune = new Commune(key, value.getString("nom"), value.getString("cpt"), value.getString("lon"), value.getString("lat"));
                liste_des_communes.add(commune);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Collections.sort(liste_des_communes, new Comparator<Commune>(){
            public int compare(Commune obj1, Commune obj2) {
                int sComp = Integer.valueOf(obj2.nombre_total).compareTo(Integer.valueOf(obj1.nombre_total));
                if (sComp != 0) { return sComp; }
                return obj1.nom.compareTo(obj2.nom);
            }
        });
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Charge le nom d'une commune
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public String chargeNomCommune(String cgid) {
        String resultat = appelPOST(SERVEUR + "/communes/list", "cgid=" + cgid);
        //Log.i(TAG,"resultat: " + resultat);
        String nom_commune = "";
        try {
            JSONObject json = new JSONObject(resultat);
            JSONObject args = json.getJSONObject("args");
            JSONObject result = args.getJSONObject(cgid);
            nom_commune = result.getString("nom");
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return nom_commune;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Vérifie si un utilisateur existe
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public boolean utilisateurExiste(String uuid) {
        String resultat = appelPOST(SERVEUR + "/protesters/get", "uid=" + uuid);
        Log.i(TAG,"resultat: " + resultat);
        try {
            JSONObject json = new JSONObject(resultat);
            String result = json.getString("result");
            if(result.equalsIgnoreCase("success")) return true;
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return false;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Charge les informations d'un utilisateur donné
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public ArrayList<String> chargeInformationsUtilisateur(String uuid) {
        String resultat = appelPOST(SERVEUR + "/protesters/get", "uid=" + uuid);
        Log.i(TAG,"resultat: " + resultat);
        ArrayList<String> info = new ArrayList<String>(2);
        try {
            JSONObject json = new JSONObject(resultat);
            String result = json.getString("result");
            if(result.equalsIgnoreCase("success")) {
                JSONObject args = json.getJSONObject("args");
                info.add(args.getString("last_seen"));
                String rgid = args.getString("rgid");
                if(rgid.equalsIgnoreCase("-1")) {
                    info.add("Position inconnue");
                }
                else if(rgid.equalsIgnoreCase("-2")) {
                    info.add("Hors France et DOM/TOM");
                }
                else {
                    String cgid = args.getString("cgid");
                    Log.e(TAG, "cgid: " + cgid);
                    if (!cgid.equalsIgnoreCase("null")) info.add(chargeNomCommune(cgid));
                    else info.add("?");
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return info;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Enregistre l'inscription de l'utilisateur
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public boolean inscriptionUtilisateur(String uuid, String longitude, String latitude) {

        // Authentification
        String url_to_sign = SERVEUR + "/protesters/add?" + "uid=" + uuid + "&position=" + longitude + "," + latitude;
        Log.e(TAG, "cle: " + cle_chiffrement);
        Log.e(TAG, "URL a signer: " + url_to_sign);
        String auth_token = retourneSignature(url_to_sign, cle_chiffrement);
        Log.e(TAG, "SHA512: " + auth_token);

        String resultat = appelPOST(SERVEUR + "/protesters/add", "uid=" + uuid + "&position=" + longitude + "," + latitude + "&auth_token=" + auth_token);
        Log.i(TAG,"resultat: " + resultat);
        try {
            JSONObject json = new JSONObject(resultat);
            Log.i(TAG, "reponse json: " + json);
            String result = json.getString("result");
            if(result.equalsIgnoreCase("success")) return true;
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return false;
    }

    // Carte avec zoom intelligent

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Dessine les annotations des régions sur la carte OSM
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void dessineAnnotationsRegionsSurLaCarte(MapView map, Context ctx) {
        Log.i(TAG, "dessineAnnotationsRegionsSurLaCarte");
        chargeRegions();
        map.getOverlays().clear();
        for(Region region : this.liste_des_regions) {
            //Log.e(TAG, "region.id: " + region.id);
            if(!region.id.equalsIgnoreCase("-1") && !region.id.equalsIgnoreCase("-2")) {
                Marker startMarker = new Marker(map);
                GeoPoint point = new GeoPoint(Float.parseFloat(region.latitude), Float.parseFloat(region.longitude));
                startMarker.setPosition(point);
                startMarker.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM);
                startMarker.setTitle(region.nom);
                String pluriel = "";
                if (Integer.parseInt(region.nombre_total) > 1) pluriel = "s";
                startMarker.setSubDescription(region.nombre_total + " gilet" + pluriel + " jaune" + pluriel);
                startMarker.setIcon(ctx.getResources().getDrawable(R.drawable.icone_32x32b));
                map.getOverlays().add(startMarker);
            }
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Dessine les annotations des départements sur la carte OSM
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void dessineAnnotationsDepartementsSurLaCarte(MapView map, Context ctx) {
        Log.i(TAG, "dessineAnnotationsDepartementsSurLaCarte");
        JSONObject resultat = localiseAvecCoordonnees(map);
        Log.i(TAG, "RES: " + resultat);
        String rgid = null;
        if(resultat != null) {
            try {
                rgid = resultat.getString("rgid");
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        Log.i(TAG, "rgid: " + rgid);

        if(rgid != null) {
            chargeDepartementsDeLaRegion(rgid);
            map.getOverlays().clear();
            for(Departement departement : this.liste_des_departements) {
                Marker startMarker = new Marker(map);
                GeoPoint point = new GeoPoint(Float.parseFloat(departement.latitude), Float.parseFloat(departement.longitude));
                startMarker.setPosition(point);
                startMarker.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM);
                startMarker.setTitle(departement.nom);
                String pluriel = "";
                if(Integer.parseInt(departement.nombre_total)>1) pluriel = "s";
                startMarker.setSubDescription(departement.nombre_total + " gilet" + pluriel + " jaune" + pluriel);
                startMarker.setIcon(ctx.getResources().getDrawable(R.drawable.icone_32x32b));
                map.getOverlays().add(startMarker);
            }
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Dessine les annotations des communes sur la carte OSM
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void dessineAnnotationsCommunesSurLaCarte(MapView map, Context ctx) {
        Log.i(TAG, "dessineAnnotationsCommunesSurLaCarte");
        JSONObject resultat = localiseAvecCoordonnees(map);
        Log.i(TAG, "RES: " + resultat);
        String dgid = null;
        if(resultat != null) {
            try {
                dgid = resultat.getString("dgid");
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        Log.i(TAG, "dgid: " + dgid);

        if(dgid != null) {
            chargeCommunesDuDepartement(dgid);
            map.getOverlays().clear();
            for(Commune commune : this.liste_des_communes) {
                Marker startMarker = new Marker(map);
                GeoPoint point = new GeoPoint(Float.parseFloat(commune.latitude), Float.parseFloat(commune.longitude));
                startMarker.setPosition(point);
                startMarker.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM);
                startMarker.setTitle(commune.nom);
                String pluriel = "";
                if(Integer.parseInt(commune.nombre_total)>1) pluriel = "s";
                startMarker.setSubDescription(commune.nombre_total + " gilet" + pluriel + " jaune" + pluriel);
                startMarker.setIcon(ctx.getResources().getDrawable(R.drawable.icone_32x32b));
                map.getOverlays().add(startMarker);
            }
        }
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Localise la commune, département et région d'un point GPS
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public JSONObject localiseAvecCoordonnees(MapView map) {

        JSONObject retour = null;

        IGeoPoint centre = map.getMapCenter();
        String lon = String.valueOf(centre.getLongitude());
        String lat = String.valueOf(centre.getLatitude());

        String resultat = appelPOST(SERVEUR + "/tools/localize", "position=" + lon + "," + lat);
        //Log.i(TAG,"resultat: " + resultat);

        try {
            JSONObject json = new JSONObject(resultat);
            String res = json.getString("result");
            if(res.equalsIgnoreCase("error")) return null;
            retour = json.getJSONObject("args");
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return retour;
    }


    // Fonctions utilitaires


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Affiche une boite de dialogue pas internet
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public void alertePasInternet(Context ctx) {
        AlertDialog.Builder adb = new AlertDialog.Builder(ctx);
        adb.setTitle("Cette application a besoin de Internet pour fonctionner !");
        //adb.setIcon(android.R.drawable.ic_dialog_alert);
        adb.setPositiveButton("OK", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
            }
        });
        adb.show();

    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Teste si le serveur est accessible
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public boolean serveurPingue(Context ctx, String serveur) {
        ConnectivityManager connectivityManager
                = (ConnectivityManager)  ctx.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        if(activeNetworkInfo != null) {
            Runtime runtime = Runtime.getRuntime();
            try {
                Process ipProcess = runtime.exec("/system/bin/ping -c 1 " + serveur);
                int exitValue = ipProcess.waitFor();
                return (exitValue == 0);
            } catch (IOException e) {
                e.printStackTrace();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        return false;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Renvoi une chaine avec la date formatée pour l'affichage
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public String convertiDate(String datestr) {
        Log.e(TAG, "date in:" + datestr);
        SimpleDateFormat informat = new SimpleDateFormat("yyyy-MM-dd' 'kk:mm:ss.SSSSSSZ");
        informat.setTimeZone(TimeZone.getTimeZone("GMT+1"));
        SimpleDateFormat outformat = new SimpleDateFormat("dd-MM-yyyy' à 'kk:mm:ss");
        outformat.setTimeZone(TimeZone.getTimeZone("GMT+1"));
        Date date = null;
        try {
            date = informat.parse(datestr);
            Log.i(TAG, "Date: " + date);
        } catch (ParseException e) {
            e.printStackTrace();
        }
        return outformat.format(date);
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Renvoi la signature d'une chaine (sha512 de la chaine + cle)
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public String retourneSignature(String chaine, String cle_chiffrement){
        String resultat = null;
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-512");
            md.update(cle_chiffrement.getBytes(StandardCharsets.UTF_8));
            byte[] bytes = md.digest(chaine.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for(int i=0; i< bytes.length ;i++){
                sb.append(Integer.toString((bytes[i] & 0xff) + 0x100, 16).substring(1));
            }
            resultat = sb.toString();
        }
        catch (NoSuchAlgorithmException e){
            e.printStackTrace();
        }
        return resultat;
    }
}