#include <iostream>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <random>
#include <fstream>
#include <iomanip>
#include "Vtop.h"

using namespace std;

int main(int argc, char *argv[])
{
  VerilatedContext *contextp = new VerilatedContext();
  contextp->debug(0);
  contextp->traceEverOn(true);
  contextp->commandArgs(argc, argv);

  Vtop *top = new Vtop(contextp, "top");
  top->clk_i = 0;

  VerilatedVcdC *tfp = new VerilatedVcdC;
  top->trace(tfp, 5);
  tfp->open("top.vcd");

  const int m = 8, k = 32, n = 8;
  vector<vector<short> > matrix_a(m);
  vector<vector<short> > matrix_b(k);
  vector<vector<short> > matrix_p(m);

  cout << "A matrix:" << endl;
  for (int i = 0; i < m; ++i) {
    matrix_a[i] = vector<short>(k);
    for (int j = 0; j < k; ++j) {
      matrix_a[i][j] = rand() & 0xffff;
      cout << setw(4) << matrix_a[i][j];
    }
    cout << endl;
  }
  cout << endl;

  cout << "B matrix:" << endl;
  for (int i = 0; i < k; ++i) {
    matrix_b[i] = vector<short>(n);
    for (int j = 0; j < n; ++j) {
      matrix_b[i][j] = rand() & 0xffff;
      cout << setw(4) << matrix_b[i][j];
    }
    cout << endl;
  }
  cout << endl;

  cout << "P matrix:" << endl;
  for (int i = 0; i < m; ++i) {
    matrix_p[i] = vector<short>(n);
    for (int j = 0; j < n; ++j) {
      int psum = 0;
      for (int l = 0; l < k; ++l) {
        psum += matrix_a[i][l] * matrix_b[l][j];
      }
      matrix_p[i][j] = psum >> 8;
      cout << setw(4) << matrix_p[i][j];
    }
    cout << endl;
  }
  cout << endl;

  cout << "P memory:" << endl;
  // Print matrix P memory content
  for (int i = 0; i < m; i += 8) {
    for (int j = 0; j < n; ++j) {
      cout << " ";
      for (int l = i + 7; l >= i; --l) {
        if (l >= m) {
          cout << "0000";
        } else {
          cout << setfill('0') << setw(4) << hex << matrix_p[l][j];
        }
      }
      cout << endl;
    }
  }

  // Write matrix A to mema.txt
  ofstream mema("tb/mema.mem");
  for (int i = 0; i < m; i += 8) {
    for (int j = 0; j < k; ++j) {
      for (int l = i + 7; l >= i; --l) {
        if (l >= m) {
          mema << "0000";
        } else {
          mema << setfill('0') << setw(4) << hex << matrix_a[l][j];
        }
      }
      mema << "\n";
    }
  }
  mema.flush();
  mema.close();

  // Write matrix B to mema.txt
  ofstream memb("tb/memb.mem");
  for (int j = 0; j < n; j += 8) {
    for (int i = 0; i < k; ++i) {
      for (int l = j + 7; l >= j; --l) {
        if (l >= n) {
          memb << "0000";
        } else {
          memb << setfill('0') << setw(4) << hex << matrix_b[i][l];
        }
      }
      memb << "\n";
    }
  }
  memb.flush();
  memb.close();

  int posedge_cnt = 0;
  while (!contextp->gotFinish() && posedge_cnt < 200) {
    top->rst_ni = 1;
    if (contextp->time() >= 1 && contextp->time() < 5) {
      top->rst_ni = 0;
      top->addr_i = 0;
      top->wdata_i = 0;
      top->we_i = 0;
    }

    top->clk_i ^= 1;
    top->eval();

    if (top->clk_i == 1) {
      posedge_cnt++;
      switch (posedge_cnt) {
      case 6:
        top->we_i = 1;
        top->addr_i = 2;
        top->wdata_i = m;  // m
        break;
      case 7:
        top->we_i = 1;
        top->addr_i = 3;
        top->wdata_i = k;  // k
        break;
      case 8:
        top->we_i = 1;
        top->addr_i = 4;
        top->wdata_i = n;  // n
        break;
      case 9:
        top->we_i = 1;
        top->addr_i = 5;
        top->wdata_i = 0xf00;  // base_addra
        break;
      case 10:
        top->we_i = 1;
        top->addr_i = 6;
        top->wdata_i = 0xf00;  // base_addrb
        break;
      case 11:
        top->we_i = 1;
        top->addr_i = 7;
        top->wdata_i = 0xf00;  // base_addrp
        break;
      case 12:
        top->we_i = 1;
        top->addr_i = 0;
        top->wdata_i = 1;  // start
        break;
      default:
        top->we_i = 0;
        top->addr_i = 0;
        top->wdata_i = 0;
      }
    }

    tfp->dump(contextp->time());
    contextp->timeInc(1);
  }

  top->final();
  tfp->flush();
  tfp->close();

  return 0;
}
