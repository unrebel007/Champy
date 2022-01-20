﻿namespace XFurStudio2 {

    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;

    [ExecuteAlways]
    public class XFurStudio2_LightManager : MonoBehaviour {

        public Light mainLight;



        private void Update() {
            
            if ( mainLight ) {
                Shader.SetGlobalVector( "_XFurMainStandardLightDir", mainLight.transform.forward );
                Shader.SetGlobalColor( "_XFurMainStandardLightColor", mainLight.color * mainLight.intensity );
            }
            else {
                Shader.SetGlobalVector( "_XFurMainStandardLightDir", mainLight.transform.forward );
                Shader.SetGlobalColor( "_XFurMainStandardLightColor", Color.black );
            }

        }


        private void OnDisable() {
            Shader.SetGlobalVector( "_XFurMainStandardLightDir", Vector3.forward );
            Shader.SetGlobalColor( "_XFurMainStandardLightColor", Color.black );
        }

    }
}