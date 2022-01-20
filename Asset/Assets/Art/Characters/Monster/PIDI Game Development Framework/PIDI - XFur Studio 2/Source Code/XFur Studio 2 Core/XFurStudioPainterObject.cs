﻿namespace XFurStudio2 {

    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;

    [RequireComponent( typeof( BoxCollider ), typeof( Rigidbody ), typeof(SphereCollider) )]
    [ExecuteAlways]
    public class XFurStudioPainterObject : MonoBehaviour {

        public enum PainterShape { Spherical, Box }
        public PainterShape PainterObjectShape;

        public XFurStudioAPI.PaintDataMode PaintDataMode = XFurStudioAPI.PaintDataMode.SnowFX;

        public Vector4 ColorBlendMask;

        public bool InvertBrush;

        public float BrushOpacity = 1.0f;

        public float BrushHardness = 1.0f;

        public Color BrushColor = Color.white;

        public Vector3 BoxSize = Vector3.one;

        public float Radius = 0.5f;

        [SerializeField] protected BoxCollider bCollider;
        [SerializeField] protected SphereCollider sCollider;
        [SerializeField] protected Rigidbody bRigid;

        private Vector3 prevPos;
        private int testPos;

#if UNITY_EDITOR
        private string version = "2.0";

        public string Version { get { return version; } }
#endif



        private void Awake() {
            GetComponent<Rigidbody>().isKinematic = true;
        }


        private void Update() {


            if (testPos == 1 ) {
                prevPos = transform.position;
                testPos = 0;
            }
            else {
                testPos = 1;
            }

            if ( !bCollider ) {
                bCollider = GetComponent<BoxCollider>();
            }

            if ( !sCollider ) {
                sCollider = GetComponent<SphereCollider>();
            }

            if ( !bRigid ) {
                bRigid = GetComponent<Rigidbody>();
            }

            bRigid.isKinematic = true;
            bRigid.hideFlags = bCollider.hideFlags = sCollider.hideFlags = HideFlags.HideInInspector;
            bCollider.size = Vector3.zero;
            bCollider.enabled = false;
            sCollider.radius = Radius;
            sCollider.enabled = PainterObjectShape == 0;
            bCollider.enabled = PainterObjectShape != 0;
            bCollider.isTrigger = sCollider.isTrigger = true;
        }


        private void OnDrawGizmos() {

            Gizmos.color = new Color( 0, 1, 0, 0.5f );

            if (PainterObjectShape == PainterShape.Spherical ) {
                Gizmos.DrawSphere( transform.position, Radius );
            }
            else {
                Gizmos.DrawCube( transform.position, BoxSize );
            }
        }

        void OnTriggerStay(Collider other) {

            if ( !Application.isPlaying ) {
                return;
            }

            var xfurSystem = other.transform.root.GetComponentInChildren<XFurStudioInstance>();

            if ( xfurSystem ) {
                if ( PainterObjectShape == PainterShape.Spherical ) {

                    var color = BrushColor;
                    var intensity = BrushOpacity;
                    var hardness = BrushHardness;

                    var pos = xfurSystem.MainRenderer.renderer.transform.InverseTransformPoint( transform.position );
                    var dir = xfurSystem.MainRenderer.renderer.transform.TransformDirection( (pos).normalized );

                    if (PaintDataMode == XFurStudioAPI.PaintDataMode.FurGrooming ) {
                        for ( int i = 0; i < xfurSystem.FurDataProfiles.Length; i++ ) {
                            if ( xfurSystem.MainRenderer.isFurMaterial[i] )
                                XFurStudioAPI.Groom( xfurSystem, i, transform.position, dir, Radius, intensity, hardness, (transform.position-prevPos).normalized );
                        }
                        return;
                    }

                    if ( PaintDataMode == XFurStudioAPI.PaintDataMode.FurMask || PaintDataMode == XFurStudioAPI.PaintDataMode.FurMask || PaintDataMode == XFurStudioAPI.PaintDataMode.FurMask || PaintDataMode == XFurStudioAPI.PaintDataMode.FurMask ) {
                        color = InvertBrush ? Color.black : Color.white;

                        if (PaintDataMode == XFurStudioAPI.PaintDataMode.FurMask ) {
                            intensity = 1.0f;
                            hardness = 1.0f;
                        }

                    }
                    else if (PaintDataMode == XFurStudioAPI.PaintDataMode.SnowFX || PaintDataMode == XFurStudioAPI.PaintDataMode.BloodFX || PaintDataMode == XFurStudioAPI.PaintDataMode.WaterFX ) {
                        color = InvertBrush ? Color.black : Color.white;
                        intensity *= Time.deltaTime;
                    }

                    for ( int i = 0; i < xfurSystem.FurDataProfiles.Length; i++ ) {
                        if (xfurSystem.MainRenderer.isFurMaterial[i])
                            XFurStudioAPI.Paint( xfurSystem, PaintDataMode, i, transform.position, dir, Radius, intensity, hardness, color, Texture2D.whiteTexture );
                    }
                }
            }
        }


    }

}