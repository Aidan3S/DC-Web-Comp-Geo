using System;
using System.Linq;
using Godot;
using MathNet.Numerics.LinearAlgebra;

namespace DualContouringBuildingGame.World.Modal {
    public class QEFSolver : Node {
        static readonly Matrix<float> middle = Matrix<float>.Build.Dense(3, 1, 0.5f);
        
        public static Vector3 solve(Vector3[] normals, Vector3[] crossings) {
            // Instantiate A and B matrices
            var normalValues = normals.Select(x => new float[] {x.x, x.y, x.z});
            var bValues = new float[crossings.Length, 1];
            for (int i = 0; i < crossings.Length; i++) {
                bValues[i, 0] = normals[i].Dot(crossings[i]);
            }
            var builder = Matrix<float>.Build;
            var A = builder.DenseOfRows(normalValues);
            var B = builder.DenseOfArray(bValues);

            var At = A.Transpose();
            var AtA = At * A;
            var AtB = At * B;
            
            var eig = AtA.Evd();
            var D0inv = builder.Dense(3, 3);
            eig.D.CopyTo(D0inv);
            D0inv.CoerceZero(1e-2);
            for (int i = 0; i < 3; i++) {
                if (D0inv[i, i] != 0.0f)
                    D0inv[i, i] = 1 / D0inv[i, i];
            }
            var U = eig.EigenVectors.Transpose();
            var res = (U.Transpose() * D0inv * U) * (AtB - AtA * middle) + middle;

            // var massPoint = crossings.Aggregate((a, b) => a + b) / crossings.Length;
            // if (res[0, 0] < 0 || res[0, 0] > 1) res[0, 0] = massPoint.x;
            // if (res[1, 0] < 0 || res[1, 0] > 1) res[1, 0] = massPoint.y;
            // if (res[2, 0] < 0 || res[2, 0] > 1) res[2, 0] = massPoint.z;

            return new Vector3(res[0, 0], res[1, 0], res[2, 0]);
        }
    }
}
